# Documentation for hive-open-source-2025

## Requirements

Following things are required at the moment, when running project locally:

- Node.js on version `24.12.0`
- NPM on version `11.7.0`

***

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

***

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

***

## Dokploy

### Automated Cron Jobs

As of right now there are some issues, the way Dokploy is doing cleanup by removing unused images etc. which means the storage gets full faster than it is supposed to. So to tackle this, we introduce automated script, which handles this for us once per day.

***

#### Daily Docker Cleanup

```#!/bin/bash
WAIT=10

echo "Starting Docker cleanup..."

while true; do
    ACTIVE_PROCESSES=$(ps aux | grep -E 'docker build|docker pull' | grep -v grep)

    if [ -z "$ACTIVE_PROCESSES" ]; then
        echo "Docker is idle. Starting cleanup..."
        break
    else
        echo "Docker is busy. Will check again in 10 seconds..."
        sleep $WAIT
    fi
done

docker container prune --force
docker image prune --all --force
docker volume prune --all --force
docker builder prune --all --force
docker system prune --all --volumes --force

echo "Docker cleanup completed."
```

***

## Supabase

### Supabase Creating Migration

When you want to make changes to your database schemas, it is best practice to create a migration file locally (obviously you are able to make schema changes at dashboard), by running following command on terminal `npm run migration:new`. It is going to ask first what is the name of the migration, so give it a descriptive name, which describes what kind of changes you are making to database schemas. Once you have given it a name, it is going to create new migration file under following location:

```bash
supabase/
└── migrations/
    └── <timestamp>_your_migration_name.sql
```

Once file has been created, you can open it and start making changes to database schemas by using SQL query. For example if you want to create new table, you can do it by using following query inside the migration file:

```sql
CREATE TABLE "guidances" (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    author TEXT NOT NULL,
    reason TEXT,
    status BOOLEAN NOT NULL DEFAULT FALSE,
    created_on TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);
```

Keep in mind, when you are creating new migration files, Supabase CLI is going to automatically attach `timestamp` to the beginning of the file name. This is important to be aware of, as Supabase is going to use that value to determine in which order the migrations should be applied to database. This means for example, if you create two migration files, the one with earlier timestamp is going to be applied first to database.

***

### Supabase Applying Migration

Let's assume you have now created an new migration file and that migration is missing currently from the database. In order to apply that migration to database, you can do so by running following command on terminal `npm run db:push:stg` or `npm run db:push:prod` depending on which environment you want to apply migration to. As of right now we don't have a database for production, but once we have one, you can use the `prod` command to apply migrations to there.

When you run that command, Supabase CLI is going to look for any new migration files, which are missing from the database and then it's going to apply those migrations in the correct order based on the timestamp attached to the beginning of the file name.

#### Prerequisites

Before we are able to apply migrations to database, there are few steps which we need to do in order to make sure that we are able to apply migrations locally:

1. On terminal make sure that you are currently on `hive-open-source-2025` project folder.
2. Make sure that you have `Tailscale` application running on your local machine as you are going to need to pass it's IP address on the next step.
3. Validate your environment variables and make sure that you have following variables set correctly:

```makefile
TAILSCALE_DEVICE_IP=<YOUR_TAILSCALE_DEVICE_IP_ADDRESS>
SUPABASE_DB_URL="postgresql://postgres:<POSTGRES_PASSWORD>@${TAILSCALE_DEVICE_IP}:5432/postgres"
PGSSLMODE="disable" ## https://github.com/supabase/cli/issues/4142#issuecomment-3270738488
```

4. Connect to the server via Tailscale SSH by running following command `ssh -L *:5432:localhost:5432 root@<tailscale_machine_name>` on terminal.
5. Once connected, leave terminal open and create new terminal window.
6. On new terminal window run following command to apply migrations `npm run db:push:stg` or `npm run db:push:prod` depending on which environment you want to apply migrations to.
7. Once migration file has been applied successfully, you can close the SSH connection.

***

### Supabase Generating Types

As we are using TypeScript on the project, and using Supabase as our main database solution, it is important to generate types from our database when we are making changes to current schemas. It is possible, we are going to automate this process in the future, but as of right now it is manual process, which means that every time you are making changes to database schemas, you need to generate types again locally and then commit those changes into repository.

To generate types from Supabase, you can do so by running following command on terminal `npm run gen:types:stg` or `npm run gen:types:prod` depending on which environment you want to generate types from. As of right now we don't have a database for production, but once we have one, you can use the `prod` command to generate types from there.

When you generate types from Supabase, it is going to create new file or overwrite existing file with a file called `database.ts`, which can be found from following location:

```bash
types/
└── database.ts
```

Then that file can be used with the Supabase client, when we are making requests against the database and then we are going to know what kind of data we are expecting back from the database.

#### Prerequisites

Before we are able to generate types from our Supabase database, there are few steps which we need to do in order to make sure that we are able to generate types locally:

1. On terminal make sure that you are currently on `hive-open-source-2025` project folder.
2. Make sure that you have `Tailscale` application running on your local machine as you are going to need to pass it's IP address on the next step.
3. Validate your environment variables and make sure that you have following variables set correctly:

```makefile
TAILSCALE_DEVICE_IP=<YOUR_TAILSCALE_DEVICE_IP_ADDRESS>
SUPABASE_DB_URL="postgresql://postgres:<POSTGRES_PASSWORD>@${TAILSCALE_DEVICE_IP}:5432/postgres"
PGSSLMODE="disable" ## https://github.com/supabase/cli/issues/4142#issuecomment-3270738488
```

4. Connect to the server via Tailscale SSH by running following command `ssh -L *:5432:localhost:5432 root@<tailscale_machine_name>` on terminal.
5. Once connected, leave terminal open and create new terminal window.
6. On new terminal window run following command to generate types `npm run gen:types:stg` or `npm run gen:types:prod` depending on which environment you want to generate types from.
7. Once types have been generated successfully, you can close the SSH connection.

#### Best practices

Ideally you would want to run type generation process everytime, when you are making changes to database schemas at `hive-open-source-2025` repository. This way you are making sure that your types are always up to date with the database structure. As of right now the flow is not automated, so there is lot of manual work involved sadly. Currently the best approach is following these steps:

1. Everytime you are making changes to database schemas at `hive-open-source-2025` repository, commit changes and migrate those changes into Supabase database.
2. Once migration is done, run the type generation process by following the prerequisites steps mentioned earlier.
3. Finally commit the generated types into repository, so that everyone else is able to use the updated types.

***
