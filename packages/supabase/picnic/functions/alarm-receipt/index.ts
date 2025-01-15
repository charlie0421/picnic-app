import "https://esm.sh/@supabase/functions-js/src/edge-runtime.d.ts";
const SLACK_WEBHOOK_URL = 'https://hooks.slack.com/services/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';
Deno.serve(async (req)=>{
  const payload = await req.json();
  const { record } = payload;
  console.log('New record:', record);
  const message = {
    text: `구매데이터가 추가되었습니다: ${record.product_id}`,
    attachments: [
      {
        color: "#36a64f",
        fields: Object.keys(record).filter((key)=>key !== 'receipt_data').map((key)=>({
            title: key,
            value: record[key],
            short: true
          }))
      }
    ]
  };
  const slackResponse = await fetch(SLACK_WEBHOOK_URL, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json'
    },
    body: JSON.stringify(message)
  });
  if (slackResponse.ok) {
    return new Response('Message sent to Slack successfully', {
      status: 200
    });
  } else {
    return new Response('Failed to send message to Slack', {
      status: 500
    });
  }
});
