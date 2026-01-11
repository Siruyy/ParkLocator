
const { Client } = require('pg');

const client = new Client({
  user: 'parklocator',
  host: 'localhost',
  database: 'parklocator',
  password: 'parklocator',
  port: 5433,
});

client.connect();

client.query(`
  SELECT column_name, data_type 
  FROM information_schema.columns 
  WHERE table_name = 'venues';
`, (err, res) => {
  if (err) {
    console.error(err);
  } else {
    console.log(res.rows);
  }
  client.end();
});
