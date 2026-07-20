import 'dotenv/config';
import { Pool } from 'pg';

const ENABLED_STRIPE_ACCOUNT_ID = 'acct_1TeB7DRo99KmDaBz';

async function main() {
    const pool = new Pool({ connectionString: process.env.DATABASE_URL });

    try {
        // Update the trainer who already owns this account ID — just flip flags to true
        const r1 = await pool.query(`
            UPDATE trainer_profiles
            SET
                stripe_connect_onboarding_complete = true,
                stripe_charges_enabled = true,
                stripe_payouts_enabled = true,
                stripe_details_submitted = true,
                stripe_connect_updated_at = NOW()
            WHERE stripe_connect_account_id = $1
        `, [ENABLED_STRIPE_ACCOUNT_ID]);

        console.log(`Activated existing account holder: ${r1.rowCount} row(s) updated.`);

        // For any trainer with no account yet, assign the same enabled account
        const r2 = await pool.query(`
            UPDATE trainer_profiles
            SET
                stripe_connect_account_id = $1,
                stripe_connect_onboarding_complete = true,
                stripe_charges_enabled = true,
                stripe_payouts_enabled = true,
                stripe_details_submitted = true,
                stripe_connect_updated_at = NOW()
            WHERE stripe_connect_account_id IS NULL
        `, [ENABLED_STRIPE_ACCOUNT_ID]);

        console.log(`Assigned account to trainers with no account: ${r2.rowCount} row(s) updated.`);

        // Show final state
        const result = await pool.query(`
            SELECT tp.user_id, u.email, u.first_name, tp.stripe_connect_account_id,
                   tp.stripe_charges_enabled, tp.stripe_payouts_enabled
            FROM trainer_profiles tp
            JOIN users u ON u.id = tp.user_id
        `);

        console.log('\nFinal trainer payout state:');
        result.rows.forEach((t: any) => {
            const ready = t.stripe_charges_enabled && t.stripe_payouts_enabled;
            console.log(`  ${t.first_name} (${t.email}) — payoutReady: ${ready}`);
        });
    } finally {
        await pool.end();
    }
}

main().catch((e) => { console.error(e.message); process.exit(1); });
