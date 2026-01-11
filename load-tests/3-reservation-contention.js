import http from 'k6/http';
import { check } from 'k6';
import { Rate, Counter } from 'k6/metrics';

// Custom metrics
export let errorRate = new Rate('errors');
export let successfulBookings = new Counter('successful_bookings');
export let conflicts = new Counter('conflicts');

export const options = {
  vus: 100, // 100 concurrent users
  duration: '10s', // All trying to book for 10 seconds
  thresholds: {
    'successful_bookings': ['count==1'], // CRITICAL: Exactly 1 booking should succeed
    'conflicts': ['count>=99'], // At least 99 should get conflicts
    'errors': ['rate==0'], // No system errors (only business logic conflicts)
  },
};

const API_BASE_URL = __ENV.API_BASE_URL || 'http://localhost:3333/api/v1';
const AUTH_TOKEN = __ENV.AUTH_TOKEN || ''; // User must provide a valid token
const SPOT_ID = __ENV.SPOT_ID || 'test-spot-id'; // User must provide
const VENUE_ID = __ENV.VENUE_ID || 'test-venue-id';
const LEVEL_ID = __ENV.LEVEL_ID || 'test-level-id';
const VEHICLE_ID = __ENV.VEHICLE_ID || ''; // User must provide a vehicle ID

export default function () {
  // All users try to book the same spot simultaneously
  const url = `${API_BASE_URL}/reservations`;
  
  const payload = JSON.stringify({
    venueId: VENUE_ID,
    levelId: LEVEL_ID,
    spotId: SPOT_ID,
    vehicleId: VEHICLE_ID,
    durationHours: 2,
  });

  const params = {
    headers: {
      'Content-Type': 'application/json',
      'Authorization': `Bearer ${AUTH_TOKEN}`,
    },
  };

  const res = http.post(url, payload, params);
  
  // Check response
  if (res.status === 201) {
    successfulBookings.add(1);
    console.log(`✅ User ${__VU} successfully booked the spot`);
    check(res, {
      'booking successful': () => true,
    });
  } else if (res.status === 409) {
    conflicts.add(1);
    check(res, {
      'got expected conflict': () => {
        try {
          const body = JSON.parse(res.body);
          return body.message && body.message.includes('already reserved');
        } catch {
          return false;
        }
      },
    });
  } else {
    errorRate.add(1);
    console.error(`❌ Unexpected status ${res.status}: ${res.body}`);
  }
}
