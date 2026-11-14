# Telegram Bot API Integration Guide

## 1. Official API Specification
- **API Product:** Official Telegram Bot API (`https://api.telegram.org/bot<token>/`)
- **Authentication Method:** Bot Token issued by official Telegram `@BotFather`
- **Supported Entities:** Public & Private Telegram Channels, Supergroups, Groups where the bot is an Administrator.

## 2. Bot Creation & Configuration Workflow
1. Open Telegram and search for `@BotFather`.
2. Send command: `/newbot`.
3. Provide a display name and unique username ending in `bot` (e.g. `SocialFlowPublisherBot`).
4. `@BotFather` returns your HTTP API Bot Token (e.g. `123456789:ABCdefGhIJKlmNoPQRsTUVwxyZ`).
5. In SocialFlow AI, navigate to **Connect New Platform -> Telegram** and paste the Bot Token.

## 3. Mandatory Channel Administrator Setup
1. Open your target Telegram Channel or Supergroup.
2. Go to **Channel Settings -> Administrators -> Add Administrator**.
3. Search for your bot's username and add it.
4. Ensure the bot has **"Post Messages"** permission enabled (`can_post_messages: true`).
5. Enter your Channel public username (e.g. `@my_tech_channel`) or Channel ID (e.g. `-1001987654321`) into SocialFlow AI to complete verification.

