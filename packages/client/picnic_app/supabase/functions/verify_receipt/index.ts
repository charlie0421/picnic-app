// Follow this setup guide to integrate the Deno language server with your editor:
// https://deno.land/manual/getting_started/setup_your_environment
// This enables autocomplete, go to definition, etc.

// Setup type definitions for built-in Supabase Runtime APIs
import "https://esm.sh/@supabase/functions-js/src/edge-runtime.d.ts"
import {createClient} from '@supabase/supabase-js';

const supabaseUrl = process.env.SUPABASE_URL;
const supabaseKey = process.env.SUPABASE_SERVICE_KEY;
const supabase = createClient(supabaseUrl, supabaseKey);


Deno.serve(async (req) => {
    const {receipt, platform} = JSON.parse(event.body);

    let response;
    if (platform === 'ios') {
        response = await fetch('https://buy.itunes.apple.com/verifyReceipt', {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
            },
            body: JSON.stringify({
                'receipt-data': receipt,
                'password': 'your_shared_secret', // App Store Connect에서 생성한 공유 비밀번호
            }),
        });
    } else if (platform === 'android') {
        response = await fetch('https://androidpublisher.googleapis.com/androidpublisher/v3/applications/packageName/purchases/products/productId/tokens/token', {
            method: 'GET',
            headers: {
                'Authorization': `Bearer ${process.env.GOOGLE_API_KEY}`, // Google API Key
            },
        });
    }

    const data = await response.json();

    if (response.status === 200 && (platform === 'ios' ? data.status === 0 : true)) {
        // 영수증이 유효함
        await supabase
            .from('receipts')
            .insert([{receipt_data: receipt, status: 'valid', platform}]);

        return {
            statusCode: 200,
            body: JSON.stringify({success: true, data: data}),
        };
    } else {
        // 영수증이 유효하지 않음
        await supabase
            .from('receipts')
            .insert([{receipt_data: receipt, status: 'invalid', platform}]);

        return {
            statusCode: 400,
            body: JSON.stringify({success: false, data: data}),
        };
    }

})

/* To invoke locally:

  1. Run `supabase start` (see: https://supabase.com/docs/reference/cli/supabase-start)
  2. Make an HTTP request:

  curl -i --location --request POST 'http://127.0.0.1:54321/functions/v1/verify_receipt' \
    --header 'Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZS1kZW1vIiwicm9sZSI6ImFub24iLCJleHAiOjE5ODM4MTI5OTZ9.CRXP1A7WOeoJeXxjNni43kdQwgnWNReilDMblYTn_I0' \
    --header 'Content-Type: application/json' \
    --data '{"name":"Functions"}'

*/
