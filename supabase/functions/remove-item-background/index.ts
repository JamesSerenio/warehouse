const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

function bytesToBase64(bytes: Uint8Array): string {
  const chunkSize = 0x8000;
  let binary = "";
  for (let offset = 0; offset < bytes.length; offset += chunkSize) {
    binary += String.fromCharCode(...bytes.subarray(offset, offset + chunkSize));
  }
  return btoa(binary);
}

Deno.serve(async (request) => {
  if (request.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const apiKey = Deno.env.get("BACKGROUND_REMOVAL_API_KEY");
    const endpoint = Deno.env.get("BACKGROUND_REMOVAL_API_URL") ??
      "https://api.remove.bg/v1.0/removebg";
    if (!apiKey) throw new Error("BACKGROUND_REMOVAL_API_KEY is not configured.");

    const body = await request.json();
    const imageBase64 = body.image_base64 as string | undefined;
    const extension = (body.input_extension as string | undefined)?.toLowerCase();
    if (!imageBase64 || !extension || !["jpg", "jpeg", "png", "webp"].includes(extension)) {
      return Response.json(
        { error: "A supported image is required." },
        { status: 400, headers: corsHeaders },
      );
    }

    const binary = atob(imageBase64.includes(",") ? imageBase64.split(",").pop()! : imageBase64);
    const bytes = Uint8Array.from(binary, (character) => character.charCodeAt(0));
    if (bytes.byteLength > 5 * 1024 * 1024) {
      return Response.json(
        { error: "Image must be 5 MB or smaller." },
        { status: 413, headers: corsHeaders },
      );
    }

    const form = new FormData();
    form.append("image_file", new Blob([bytes]), `product.${extension}`);
    form.append("size", "auto");
    form.append("format", "png");

    const providerResponse = await fetch(endpoint, {
      method: "POST",
      headers: { "X-Api-Key": apiKey },
      body: form,
    });
    if (!providerResponse.ok) {
      const providerError = await providerResponse.text();
      console.error("BACKGROUND REMOVAL PROVIDER ERROR", providerResponse.status, providerError);
      return Response.json(
        { error: "Background removal failed." },
        { status: 502, headers: corsHeaders },
      );
    }

    const pngBytes = new Uint8Array(await providerResponse.arrayBuffer());
    return Response.json(
      { image_base64: bytesToBase64(pngBytes) },
      { headers: { ...corsHeaders, "Content-Type": "application/json" } },
    );
  } catch (error) {
    console.error("REMOVE BACKGROUND FUNCTION ERROR", error);
    return Response.json(
      { error: "Background removal failed." },
      { status: 500, headers: corsHeaders },
    );
  }
});
