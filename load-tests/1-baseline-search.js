import http from 'k6/http';
import { check, sleep } from 'k6';
import { Rate } from 'k6/metrics';

// Custom metrics
export let errorRate = new Rate('errors');

export const options = {
  stages: [
    { duration: '30s', target: 100 },  // Ramp up to 100 users
    { duration: '1m', target: 500 },   // Ramp to 500 users
    { duration: '2m', target: 500 },   // Stay at 500 users
    { duration: '30s', target: 0 },    // Ramp down
  ],
  thresholds: {
    'http_req_duration': ['p(95)<300', 'p(99)<600'], // 95% under 300ms, 99% under 600ms
    'errors': ['rate<0.01'],  // Error rate under 1%
    'http_req_failed': ['rate<0.01'], //  HTTP failure rate under 1%
  },
};

const API_BASE_URL = __ENV.API_BASE_URL || 'http://localhost:3333/api/v1';

// Sample coordinates  (Cebu City, Philippines)
const coordinates = [
  { lat: 10.3157, lng: 123.8854, name: 'Downtown Cebu' },
  { lat: 10.3181, lng: 123.8970, name: 'IT Park' },
  { lat: 10.3449, lng: 123.9357, name: 'Mactan' },
  { lat: 10.2927, lng: 123.8998, name: 'South Road Properties' },
];

export default function () {
  // Pick random coordinates
  const coord = coordinates[Math.floor(Math.random() * coordinates.length)];
  const radius = 5; // 5km radius

  // Test /venues/nearby endpoint (most common for mobile users)
  const url = `${API_BASE_URL}/venues/nearby?lat=${coord.lat}&lng=${coord.lng}&radius=${radius}`;
  
  const res = http.get(url);
  
  // Check response
  const success = check(res, {
    'status is 200': (r) => r.status === 200,
    'response time < 300ms': (r) => r.timings.duration < 300,
    'has venues in response': (r) => {
      try {
        const body = JSON.parse(r.body);
        return Array.isArray(body) || (body.data && Array.isArray(body.data));
      } catch {
        return false;
      }
    },
  });

  errorRate.add(!success);

  // Simulate user "thinking time" between requests
  sleep(Math.random() * 2 + 1); // 1-3 seconds
}
