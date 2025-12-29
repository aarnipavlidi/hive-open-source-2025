import { execSync } from 'child_process';
import inquirer from 'inquirer';

const SUPABASE_DB_URL = process.env.SUPABASE_DB_URL;

function parseSupabaseMigrationList(raw) {
  const lines = raw.split('\n').filter(line =>
    line.match(/^\s*[0-9 ]{14}\s*\|\s*[0-9 ]{14}\s*\|/)
    || line.match(/^\s*[0-9 ]{14}\s*\|\s*\s*\|/)
    || line.match(/^\s*\|\s*[0-9 ]{14}\s*\|/)
  );

  return lines.map(line => {
    const [local, remote, time] = line.split('|').map(s => s.trim());
    return { local: local || '', remote: remote || '', time: time || '' };
  });
};

function getSupabaseMigrationList() {
  const result = execSync(`supabase migration list --db-url "${SUPABASE_DB_URL}"`, { encoding: 'utf8' });
  return result;
};

async function main() {
  const rawMigrations = getSupabaseMigrationList();
  const formattedMigrations = parseSupabaseMigrationList(rawMigrations);


  const migrationStatus = formattedMigrations.filter(
    val => (val.local && !val.remote) || (!val.local && val.remote)
  );

  if (migrationStatus.length === 0) {
    console.log('✅ Both local and remote migrations for Supabase are in sync. Repair is not needed.');
    return;
  };

  const options = migrationStatus.map(val => {
    if (val.local && !val.remote) {
      return {
        name: `Local only: ${val.local} (should mark as applied on remote)`,
        value: {
          version: val.local,
          status: 'applied',
        },
      };
    };

    if (!val.local && val.remote) {
      return {
        name: `Remote only: ${val.remote} (should mark as reverted on local)`,
        value: {
          version: val.remote,
          status: 'reverted',
        },
      };
    };
  });

  const { repair } = await inquirer.prompt([
    {
      type: 'list',
      name: 'repair',
      message: 'Select a migration to repair:',
      choices: options,
    },
  ]);

  const command = `supabase migration repair ${repair.version} --status ${repair.status} --db-url "${SUPABASE_DB_URL}"`;
  console.log(`✅ Successfully repaired migration ${repair.version} with status: ${repair.status}.`);

  execSync(command, {
    stdio: 'inherit'
  });
};

main();
