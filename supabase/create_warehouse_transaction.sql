begin;

create unique index if not exists transactions_transaction_code_key
  on public.transactions (upper(transaction_code));

create or replace function public.create_warehouse_transaction(
  p_transaction_code text,
  p_borrower_name text,
  p_contact_number text,
  p_note text,
  p_signature_path text,
  p_items jsonb
)
returns jsonb
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_transaction_id public.transactions.id%type;
  v_item_id public.items.id%type;
  v_item public.items%rowtype;
  v_entry jsonb;
  v_quantity integer;
  v_expected_return_at timestamptz;
  v_new_available integer;
  v_line_status text;
  v_movement_type text;
begin
  if auth.uid() is null then
    raise exception 'Authentication is required.' using errcode = '42501';
  end if;

  p_transaction_code := upper(trim(coalesce(p_transaction_code, '')));
  if p_transaction_code !~ '^[A-Z0-9]{4}$' then
    raise exception 'Invalid transaction code format.';
  end if;
  if trim(coalesce(p_borrower_name, '')) = '' then
    raise exception 'Borrower name is required.';
  end if;
  if trim(coalesce(p_contact_number, '')) = '' then
    raise exception 'Contact number is required.';
  end if;
  if p_items is null
     or jsonb_typeof(p_items) <> 'array'
     or jsonb_array_length(p_items) = 0 then
    raise exception 'Please add at least one item.';
  end if;
  if trim(coalesce(p_signature_path, '')) = '' then
    raise exception 'Signature path is required.';
  end if;

  if exists (
    select 1
    from jsonb_array_elements(p_items) entry
    group by entry ->> 'item_id'
    having count(*) > 1
  ) then
    raise exception 'Duplicate transaction items are not allowed.';
  end if;

  insert into public.transactions (
    transaction_code,
    borrower_name,
    contact_number,
    note,
    signature_path,
    status
  )
  values (
    p_transaction_code,
    trim(p_borrower_name),
    trim(p_contact_number),
    nullif(trim(coalesce(p_note, '')), ''),
    trim(p_signature_path),
    'active'
  )
  returning id into v_transaction_id;

  for v_entry in select value from jsonb_array_elements(p_items)
  loop
    v_item_id := v_entry ->> 'item_id';
    v_quantity := (v_entry ->> 'quantity')::integer;

    if v_quantity is null or v_quantity < 1 then
      raise exception 'Every transaction quantity must be at least 1.';
    end if;

    select *
      into v_item
      from public.items
     where id = v_item_id
       and is_active = true
     for update;

    if not found then
      raise exception 'Item not found or inactive.';
    end if;

    if v_quantity > v_item.available_stock then
      raise exception 'Not enough stock available for %.', v_item.product_name;
    end if;

    if v_item.item_type in ('tool', 'equipment') then
      if nullif(v_entry ->> 'expected_return_at', '') is null then
        raise exception 'Expected return date is required for %.', v_item.product_name;
      end if;
      v_expected_return_at := (v_entry ->> 'expected_return_at')::timestamptz;
      v_line_status := 'active';
      v_movement_type := 'borrow';
    elsif v_item.item_type = 'material' then
      v_expected_return_at := null;
      v_line_status := 'issued';
      v_movement_type := 'material_issued';
    else
      raise exception 'Invalid item type for %.', v_item.product_name;
    end if;

    v_new_available := v_item.available_stock - v_quantity;

    insert into public.transaction_items (
      transaction_id,
      item_id,
      quantity,
      returned_quantity,
      item_type,
      expected_return_at,
      status
    )
    values (
      v_transaction_id,
      v_item.id,
      v_quantity,
      0,
      v_item.item_type,
      v_expected_return_at,
      v_line_status
    );

    if v_item.item_type in ('tool', 'equipment') then
      update public.items
         set available_stock = v_new_available,
             borrowed_stock = coalesce(borrowed_stock, 0) + v_quantity,
             updated_at = now()
       where id = v_item.id;
    else
      update public.items
         set available_stock = v_new_available,
             updated_at = now()
       where id = v_item.id;
    end if;

    insert into public.stock_movements (
      item_id,
      movement_type,
      quantity,
      balance_after,
      reference_code,
      note
    )
    values (
      v_item.id,
      v_movement_type,
      -v_quantity,
      v_new_available,
      p_transaction_code,
      case
        when v_item.item_type = 'material' then 'Material issued'
        else 'Borrowed for transaction'
      end
    );
  end loop;

  return jsonb_build_object(
    'transaction_id', v_transaction_id,
    'transaction_code', p_transaction_code
  );
end;
$$;

revoke all on function public.create_warehouse_transaction(
  text, text, text, text, text, jsonb
) from public;

grant execute on function public.create_warehouse_transaction(
  text, text, text, text, text, jsonb
) to authenticated;

insert into storage.buckets (id, name, public)
values ('signatures', 'signatures', false)
on conflict (id) do update set public = false;

drop policy if exists "Authenticated users upload signatures" on storage.objects;
create policy "Authenticated users upload signatures"
on storage.objects for insert
to authenticated
with check (bucket_id = 'signatures');

drop policy if exists "Authenticated users view signatures" on storage.objects;
create policy "Authenticated users view signatures"
on storage.objects for select
to authenticated
using (bucket_id = 'signatures');

drop policy if exists "Authenticated users delete signatures" on storage.objects;
create policy "Authenticated users delete signatures"
on storage.objects for delete
to authenticated
using (bucket_id = 'signatures');

commit;