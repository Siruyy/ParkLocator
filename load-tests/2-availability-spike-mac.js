import http from 'k6/http';
import { check, sleep } from 'k6';
import { Rate } from 'k6/metrics';

// Custom metrics
export let errorRate = new Rate('errors');

export const options = {
  stages: [
    { duration: '10s', target: 0 },     // Start calm
    { duration: '15s', target: 500 },   // SPIKE to 500 users (more Mac-friendly)
    { duration: '1m30s', target: 500 }, // Hold spike
    { duration: '30s', target: 0 },     // Ramp down
  ],
  thresholds: {
    'http_req_duration': ['p(95)<600', 'p(99)<1000'], // More relaxed during spike
    'errors': ['rate<0.10'],  // Allow up to 10% errors during spike
    'http_req_failed': ['rate<0.05'],
  },
};

const API_BASE_URL = __ENV.API_BASE_URL || 'http://localhost:3333/api/v1';

// For this test, we'll focus on a single venue to maximize cache effectiveness
const VENUE_ID = __ENV.VENUE_ID || '5f1714cb-9268-47d6-a53a-e5c1bb78b9c8';

export default function () {
  // Test availability endpoint (high traffic during events)
  const url = `${API_BASE_URL}/venues/${VENUE_ID}/availability`;
  
  const res = http.get(url);
  
  // Check response
  const success = check(res, {
    'status is 200': (r) => r.status === 200,
    'response time < 600ms': (r) => r.timings.duration < 600,
    'has availability data': (r) => {
      try {
        const body = JSON.parse(r.body);
        return body.success === true && Array.isArray(body.data);
      } catch {
        return false;
      }
    },
  });

  errorRate.add(!success);

  // During a spike, users refresh quickly
  sleep(Math.random() * 0.5 + 0.2); // 0.2-0.7 seconds (rapid refreshing)
}
