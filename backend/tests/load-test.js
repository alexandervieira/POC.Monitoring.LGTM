import http from 'k6/http';
import { check, sleep } from 'k6';

export const options = {
  vus: 30,
  iterations: 3000,
};

export default function () {
  const contadorResponse = http.get('http://localhost:5101/contador');
  check(contadorResponse, {
    'contador: status é 200 OK': (r) => r.status === 200,
  });

  const badRequestResponse = http.get('http://localhost:5101/badrequest');
  check(badRequestResponse, {
    'badrequest: status é 400 Bad Request': (r) => r.status === 400,
  });

  const errorResponse = http.get('http://localhost:5101/error');
  check(errorResponse, {
    'error: status é 500': (r) => r.status === 500,
  });

  sleep(1);
}