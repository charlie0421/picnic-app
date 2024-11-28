#!/usr/bin/env node
import fs from 'fs/promises';
import path from 'path';
import dotenv from 'dotenv';
import pg from 'pg';

const {Pool} = pg;

// Load environment variables
dotenv.config();

const FORTUNE_EDGE_URL = 'https://api.picnic.fan/functions/v1/fortune-teller';
const BATCH_SIZE = 20;
const DELAY_MS = 1000;
const RESULTS_DIR = './results';
const LOG_FILE = path.join(RESULTS_DIR, 'fortune_batch_log.json');

// PostgreSQL 연결 설정
const pool = new Pool({
    connectionString: process.env.DATABASE_URL,
    ssl: {rejectUnauthorized: false}
});

async function delay(ms) {
    return new Promise(resolve => setTimeout(resolve, ms));
}

async function ensureResultsDirectory() {
    try {
        await fs.access(RESULTS_DIR);
    } catch {
        await fs.mkdir(RESULTS_DIR);
    }
}

async function fetchArtistsFromDB() {
    try {
        const query = `
            SELECT id,
                   name,
                   birth_date,
                   gender,
                   created_at,
                   updated_at,
                   deleted_at
            FROM artist
            WHERE deleted_at IS NULL
              AND id != 0
            ORDER BY id;
        `;

        const {rows} = await pool.query(query);
        console.log(`Found ${rows.length} active artists in database`);
        return rows;
    } catch (error) {
        console.error('Error fetching artists from database:', error);
        throw error;
    }
}

async function generateSingleFortune(artist_id, year) {
    const response = await fetch(FORTUNE_EDGE_URL, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json',
            'Authorization': `Bearer ${process.env.SUPABASE_ANON_KEY}`,
        },
        body: JSON.stringify({artist_id, year}),
    });

    if (!response.ok) {
        throw new Error(
            `HTTP error! status: ${response.status}, message: ${await response.text()}`,
        );
    }

    return response.json();
}

async function processBatch(artists, year) {
    const batchLog = {
        year,
        total_artists: artists.length,
        processed_count: 0,
        failed_count: 0,
        status: 'processing',
        started_at: new Date().toISOString(),
        results: [],
    };

    try {
        for (let i = 0; i < artists.length; i += BATCH_SIZE) {
            const batch = artists.slice(i, i + BATCH_SIZE);
            console.log(`Processing batch ${i / BATCH_SIZE + 1} of ${Math.ceil(artists.length / BATCH_SIZE)}`);

            const promises = batch.map(async (artist) => {
                try {
                    const formattedName = artist.name.ko || artist.name.en || Object.values(artist.name)[0];
                    console.log(`Processing artist: ${formattedName} (ID: ${artist.id})`);

                    const result = await generateSingleFortune(artist.id, year);
                    batchLog.processed_count++;

                    const artistResult = {
                        artist_id: artist.id,
                        artist_name: formattedName,
                        year,
                        fortune: result,
                        processed_at: new Date().toISOString()
                    };

                    await fs.writeFile(
                        path.join(RESULTS_DIR, `fortune_${year}_${artist.id}.json`),
                        JSON.stringify(artistResult, null, 2)
                    );

                    batchLog.results.push({
                        artist_id: artist.id,
                        artist_name: formattedName,
                        status: 'success'
                    });

                    console.log(`✓ Artist ${formattedName} processed successfully`);
                } catch (error) {
                    batchLog.failed_count++;
                    batchLog.results.push({
                        artist_id: artist.id,
                        artist_name: artist.name.ko || artist.name.en,
                        status: 'failed',
                        error: error.message
                    });
                    console.error(`✗ Failed to process artist ${artist.id}:`, error.message);
                }
            });

            await Promise.all(promises);

            batchLog.last_updated = new Date().toISOString();
            await fs.writeFile(LOG_FILE, JSON.stringify(batchLog, null, 2));

            if (i + BATCH_SIZE < artists.length) {
                console.log(`Waiting ${DELAY_MS}ms before next batch...`);
                await delay(DELAY_MS);
            }
        }

        batchLog.status = 'completed';
        batchLog.completed_at = new Date().toISOString();
    } catch (error) {
        console.error('Batch processing error:', error);
        batchLog.status = 'failed';
        batchLog.error = error.message;
    }

    await fs.writeFile(LOG_FILE, JSON.stringify(batchLog, null, 2));
    return batchLog;
}

async function main() {
    try {
        const year = parseInt(process.argv[2]);

        if (!year || year < 2000 || year > 2100) {
            console.error('Error: Please provide a valid year between 2000 and 2100');
            console.error('Usage: node fortune-fortune-batch.js <year>');
            process.exit(1);
        }

        if (!process.env.SUPABASE_ANON_KEY) {
            console.error('Error: SUPABASE_ANON_KEY environment variable must be set');
            process.exit(1);
        }

        await ensureResultsDirectory();

        console.log('Fetching artists from database...');
        const artists = await fetchArtistsFromDB();

        console.log(`Starting batch process for year ${year} with ${artists.length} artists`);
        const result = await processBatch(artists, year);

        console.log('\nBatch processing completed:');
        console.log(`Total artists: ${result.total_artists}`);
        console.log(`Processed: ${result.processed_count}`);
        console.log(`Failed: ${result.failed_count}`);
        console.log(`Status: ${result.status}`);
        console.log(`Results saved in: ${RESULTS_DIR}`);
    } finally {
        await pool.end();
    }
}

main().catch(error => {
    console.error('Error in main:', error);
    process.exit(1);
});
