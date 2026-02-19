#!/bin/bash
# 顯示當前對話的 Chat ID

BOT_TOKEN="8241729786:AAFSGGLYOsEHXI28PBQwZ50-JqNzx-1voo4"

echo "請在 Telegram 中向 Bot 發送任意消息（例如：'hi'）"
echo "然後按 Enter 查看你的 Chat ID..."
read -r

curl -s "https://api.telegram.org/bot${BOT_TOKEN}/getUpdates" | python3 -c "
import sys, json
data = json.load(sys.stdin)
if data.get('ok') and data.get('result'):
    for update in reversed(data['result']):
        if 'message' in update:
            chat = update['message']['chat']
            print(f\"Chat ID: {chat['id']}\")
            print(f\"Type: {chat['type']}\")
            if 'username' in chat:
                print(f\"Username: @{chat['username']}\")
            if 'first_name' in chat:
                print(f\"Name: {chat['first_name']}\")
            break
else:
    print('沒有找到消息')
    print('完整回應:', json.dumps(data, indent=2))
"
