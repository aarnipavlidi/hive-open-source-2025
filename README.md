
# hive-open-source-2025

[![Staging Deployment Status](https://github.com/aarnipavlidi/hive-open-source-2025/actions/workflows/staging.deploy.yml/badge.svg)](https://github.com/aarnipavlidi/hive-open-source-2025/actions/workflows/staging.deploy.yml)

## Requirements

Following things are required at the moment, when running project locally:

- Node.js on version `24.11.1`
- NPM on version `11.6.2`

## Getting Started (development)

Run the development server locally:

```/dev/null/commands.sh#L1-6
npm run dev
# or
yarn dev
# or
pnpm dev
# or
bun dev
```

Open `http://localhost:3000` in your browser. Edit `app/page.tsx` to see live reloads.

## Running with Docker locally

Before building or running the Docker image locally, make sure you have a `.env.local` file at the project root. The Docker run script in `package.json` expects `.env.local` and will load environment variables from it.

At a minimum set `PORT` in `.env.local` (the repository's `package.json` run script maps port `3001` by default). Example `.env.local`:

```/dev/null/example.env#L1-4
PORT=3001
# Add any other runtime ENV variables your app needs, e.g.:
# NEXT_PUBLIC_API_URL=https://api.example.com
```

This repo provides convenient npm scripts in `package.json`:

- `docker:build:local` — builds the Docker image
- `docker:run:local` — runs the image loading `.env.local` and mapping port `3001`

Use the npm scripts:

```/dev/null/commands.sh#L7-12
npm run docker:build:local
npm run docker:run:local
```
