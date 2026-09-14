begin;

create or replace function public.process_item_return(
  p_transaction_id uuid,
  p_returns jsonb,
  p_note text default null
)
returns jsonb
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_transaction public.transactions%rowtype;
  v_line public.transaction_items%rowtype;
  v_item public.items%rowtype;
  v_entry jsonb;
  v_line_id public.transaction_items.id%type;
  v_quantity integer;
  v_remaining integer;
  v_new_returned integer;
  v_new_available integer;
  v_new_borrowed integer;
  v_total_returned integer := 0;
  v_transaction_status text;
begin
  if auth.uid() is null then
    raise exception 'Authentication is required.' using errcode = '42501';
  end if;

  select * into v_transaction
    from public.transactions
   where id = p_transaction_id
   for update;
  if not found then raise exception 'Transaction not found.'; end if;

  if p_returns is null or jsonb_typeof(p_returns) <> 'array'
     or jsonb_array_length(p_returns) = 0 then
    raise exception 'No return items were selected.';
  end if;
  if exists (
    select 1 from jsonb_array_elements(p_returns) entry
    group by entry ->> 'transaction_item_id' having count(*) > 1
  ) then
    raise exception 'Duplicate return items are not allowed.';
  end if;

  for v_entry in select value from jsonb_array_elements(p_returns)
  loop
    v_line_id := (v_entry ->> 'transaction_item_id');
    v_quantity := (v_entry ->> 'quantity')::integer;
    if v_quantity is null or v_quantity <= 0 then
      raise exception 'Return quantity must be greater than zero.';
    end if;

    select * into v_line from public.transaction_items
     where id = v_line_id and transaction_id = p_transaction_id
     for update;
    if not found then raise exception 'Transaction item not found.'; end if;
    if v_line.item_type not in ('tool', 'equipment') then
      raise exception 'Materials cannot be returned.';
    end if;

    v_remaining := v_line.quantity - coalesce(v_line.returned_quantity, 0);
    if v_quantity > v_remaining then
      raise exception 'Only % item(s) remain to be returned.', v_remaining;
    end if;

    select * into v_item from public.items where id = v_line.item_id for update;
    if not found then raise exception 'Inventory item not found.'; end if;
    if coalesce(v_item.borrowed_stock, 0) < v_quantity then
      raise exception 'Borrowed stock is inconsistent.';
    end if;

    v_new_returned := coalesce(v_line.returned_quantity, 0) + v_quantity;
    v_new_available := coalesce(v_item.available_stock, 0) + v_quantity;
    v_new_borrowed := coalesce(v_item.borrowed_stock, 0) - v_quantity;

    update public.transaction_items
       set returned_quantity = v_new_returned,
           status = case when v_new_returned = quantity
                         then 'returned' else 'partial_return' end
     where id = v_line.id;

    update public.items
       set available_stock = v_new_available,
           borrowed_stock = v_new_borrowed,
           updated_at = now()
     where id = v_item.id;

    insert into public.return_history (
      transaction_id, transaction_item_id, quantity_returned, note, returned_at
    ) values (
      p_transaction_id, v_line.id, v_quantity,
      nullif(trim(coalesce(p_note, '')), ''), now()
    );

    insert into public.stock_movements (
      item_id, movement_type, quantity, balance_after, reference_code, note, created_at
    ) values (
      v_item.id, 'return', v_quantity, v_new_available,
      v_transaction.transaction_code,
      nullif(trim(coalesce(p_note, '')), ''), now()
    );
    v_total_returned := v_total_returned + v_quantity;
  end loop;

  if exists (
    select 1 from public.transaction_items
     where transaction_id = p_transaction_id
       and item_type in ('tool', 'equipment')
       and quantity - coalesce(returned_quantity, 0) > 0
  ) then
    v_transaction_status := 'partial_return';
  else
    v_transaction_status := 'completed';
  end if;

  update public.transactions
     set status = v_transaction_status, updated_at = now()
   where id = p_transaction_id;

  return jsonb_build_object(
    'transaction_id', p_transaction_id,
    'transaction_status', v_transaction_status,
    'returned_quantity', v_total_returned
  );
end;
$$;

revoke all on function public.process_item_return(uuid, jsonb, text) from public;
grant execute on function public.process_item_return(uuid, jsonb, text) to authenticated;

commit;
