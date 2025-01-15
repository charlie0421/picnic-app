import "https://esm.sh/@supabase/functions-js/src/edge-runtime.d.ts";

const SLACK_WEBHOOK_URL = 'https://hooks.slack.com/services/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';

Deno.serve(async (req) => {
    const payload = await req.json();
    const {record} = payload;

    // status가 pending이 아닌 경우 무시 (추가 안전장치)
    if (record.status !== 'pending') {
        return new Response('Ignored - status is not pending', {status: 200});
    }

    console.log('New pending board:', record);

    const message = {
        text: `게시판 생성 요청이 들어왔습니다.`,
        attachments: [
            {
                color: "#FFA500", // Orange color for pending status
                fields: [
                    {
                        title: "Board ID",
                        value: record.board_id,
                        short: true
                    },
                    {
                        title: "Name",
                        value: JSON.stringify(record.name),
                        short: true
                    },
                    {
                        title: "Artist ID",
                        value: record.artist_id.toString(),
                        short: true
                    },
                    {
                        title: "Status",
                        value: record.status,
                        short: true
                    },
                    {
                        title: "Request Message",
                        value: record.request_message || "없음",
                        short: false
                    },
                    {
                        title: "Created At",
                        value: new Date(record.created_at).toLocaleString(),
                        short: true
                    }
                ]
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
