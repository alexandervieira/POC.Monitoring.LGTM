import http from 'k6/http';
import { check, sleep } from 'k6';
import { randomString, randomIntBetween } from 'https://jslib.k6.io/k6-utils/1.2.0/index.js';

export const options = {
  vus: 30,
  iterations: 3000,
  // Opções adicionais para análise
  thresholds: {
    http_req_duration: ['p(95)<500'], // 95% das requisições devem ser abaixo de 500ms
    http_req_failed: ['rate<0.01'],   // menos de 1% de falhas
  },
};

// Função para gerar CPF válido (apenas para teste)
function generateCPF() {
  const n = Math.floor(Math.random() * 1000000000).toString().padStart(9, '0');
  return `${n.slice(0,3)}.${n.slice(3,6)}.${n.slice(6,9)}-${Math.floor(Math.random() * 90 + 10)}`;
}

// Função para gerar email
function generateEmail() {
  const domains = ['gmail.com', 'hotmail.com', 'yahoo.com.br', 'outlook.com', 'empresa.com.br'];
  const names = ['joao', 'maria', 'jose', 'ana', 'carlos', 'lucia', 'pedro', 'paula'];
  const randomName = names[Math.floor(Math.random() * names.length)];
  const randomNum = Math.floor(Math.random() * 1000);
  const domain = domains[Math.floor(Math.random() * domains.length)];
  return `${randomName}${randomNum}@${domain}`;
}

// Função para gerar telefone
function generatePhone() {
  const ddd = Math.floor(Math.random() * 90 + 10).toString();
  const prefix = Math.floor(Math.random() * 9000 + 1000).toString();
  const suffix = Math.floor(Math.random() * 9000 + 1000).toString();
  
  // Formatos variados para testar diferentes padrões
  const formats = [
    `(${ddd}) ${prefix}-${suffix}`,
    `${ddd} ${prefix}${suffix}`,
    `${ddd}${prefix}${suffix}`,
    `+55 ${ddd} ${prefix}-${suffix}`
  ];
  
  return formats[Math.floor(Math.random() * formats.length)];
}

// Função para gerar dados sensíveis em diferentes formatos
function generateSensitiveData() {
  const data = {
    cpf: generateCPF(),
    email: generateEmail(),
    telefone: generatePhone(),
    cartao: `${Math.floor(Math.random() * 9000 + 1000)} ${Math.floor(Math.random() * 9000 + 1000)} ${Math.floor(Math.random() * 9000 + 1000)} ${Math.floor(Math.random() * 9000 + 1000)}`,
    rg: `${Math.floor(Math.random() * 90 + 10)}.${Math.floor(Math.random() * 900 + 100)}.${Math.floor(Math.random() * 900 + 100)}-${Math.floor(Math.random() * 9)}`,
    cep: `${Math.floor(Math.random() * 90000 + 10000)}-${Math.floor(Math.random() * 900 + 100)}`,
    token: `token_${randomString(20)}`,
    api_key: `api_key_${randomString(20)}`,
    password: `senha_${randomString(8)}`,
    jwt: `eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxMjM0NTY3ODkwIiwibmFtZSI6IkpvaG4gRG9lIiwiaWF0IjoxNTE2MjM5MDIyfQ.SflKxwRJSMeKKF2QT4fwpMeJf36POk6yJV_adQssw5c`
  };
  return data;
}

export default function () {
  const sensitiveData = generateSensitiveData();
  
  // ===================================================
  // TESTE 1: Enviar dados sensíveis via query string
  // ===================================================
  const queryUrl = `http://localhost:5101/contador?cpf=${sensitiveData.cpf}&email=${sensitiveData.email}&telefone=${encodeURIComponent(sensitiveData.telefone)}&token=${sensitiveData.token}`;
  
  const queryResponse = http.get(queryUrl);
  check(queryResponse, {
    'query string: status é 200 OK': (r) => r.status === 200,
    'query string: dados sensíveis em URL': (r) => true, // apenas para contagem
  });

  // ===================================================
  // TESTE 2: Enviar dados sensíveis via headers
  // ===================================================
  const headersResponse = http.get('http://localhost:5101/contador', {
    headers: {
      'X-API-Key': sensitiveData.api_key,
      'Authorization': `Bearer ${sensitiveData.jwt}`,
      'X-User-CPF': sensitiveData.cpf,
      'X-User-Email': sensitiveData.email,
      'X-User-Token': sensitiveData.token,
    },
  });
  
  check(headersResponse, {
    'headers: status é 200 OK': (r) => r.status === 200,
    'headers: dados sensíveis em headers': (r) => true,
  });

  // ===================================================
  // TESTE 3: Enviar dados sensíveis via body (POST simulado)
  // ===================================================
  const payload = JSON.stringify({
    nome: "Usuário Teste",
    cpf: sensitiveData.cpf,
    email: sensitiveData.email,
    telefone: sensitiveData.telefone,
    cartao: sensitiveData.cartao,
    rg: sensitiveData.rg,
    cep: sensitiveData.cep,
    senha: sensitiveData.password,
    observacoes: `Dados do cliente: CPF ${sensitiveData.cpf}, Email ${sensitiveData.email}, Telefone ${sensitiveData.telefone}`
  });

  const postResponse = http.post('http://localhost:5101/contador', payload, {
    headers: {
      'Content-Type': 'application/json',
      'X-API-Key': sensitiveData.api_key,
    },
  });
  
  check(postResponse, {
    'post body: status é 200 OK': (r) => r.status === 200,
    'post body: dados sensíveis em JSON': (r) => true,
  });

  // ===================================================
  // TESTE 4: Endpoints de erro com dados sensíveis
  // ===================================================
  const badRequestUrl = `http://localhost:5101/badrequest?email=${sensitiveData.email}&token=${sensitiveData.token}`;
  const badRequestResponse = http.get(badRequestUrl);
  check(badRequestResponse, {
    'badrequest: status é 400 Bad Request': (r) => r.status === 400,
    'badrequest: dados sensíveis em erro': (r) => true,
  });

  const errorUrl = `http://localhost:5101/error?cpf=${sensitiveData.cpf}&api_key=${sensitiveData.api_key}`;
  const errorResponse = http.get(errorUrl);
  check(errorResponse, {
    'error: status é 500': (r) => r.status === 500,
    'error: dados sensíveis em erro': (r) => true,
  });

  // ===================================================
  // TESTE 5: Múltiplos dados sensíveis em uma única requisição
  // ===================================================
  const complexUrl = `http://localhost:5101/contador?` +
    `cpf=${sensitiveData.cpf}` +
    `&cnpj=12.345.678/0001-90` +
    `&email=${sensitiveData.email}` +
    `&telefone=${encodeURIComponent(sensitiveData.telefone)}` +
    `&cartao=${sensitiveData.cartao.replace(/ /g, '')}` +
    `&token=${sensitiveData.token}` +
    `&api_key=${sensitiveData.api_key}` +
    `&password=${sensitiveData.password}` +
    `&jwt=${sensitiveData.jwt}`;

  const complexResponse = http.get(complexUrl);
  check(complexResponse, {
    'complexo: status é 200 OK': (r) => r.status === 200,
  });

  // ===================================================
  // TESTE 6: Dados sensíveis em User-Agent (incomum, mas possível)
  // ===================================================
  const userAgentResponse = http.get('http://localhost:5101/contador', {
    headers: {
      'User-Agent': `Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (CPF: ${sensitiveData.cpf}, Email: ${sensitiveData.email})`,
    },
  });
  
  check(userAgentResponse, {
    'user-agent: status é 200 OK': (r) => r.status === 200,
  });

  // ===================================================
  // TESTE 7: Log estruturado com dados sensíveis
  // ===================================================
  const logPayload = JSON.stringify({
    level: "info",
    message: "Processando dados do usuário",
    user: {
      cpf: sensitiveData.cpf,
      email: sensitiveData.email,
      telefone: sensitiveData.telefone,
    },
    transaction: {
      id: randomString(10),
      amount: randomIntBetween(100, 10000),
      card: sensitiveData.cartao,
    },
    metadata: {
      source: "load-test",
      timestamp: new Date().toISOString(),
    }
  });

  const logResponse = http.post('http://localhost:5101/contador', logPayload, {
    headers: {
      'Content-Type': 'application/json',
      'X-Logging': 'sensitive-data-test',
    },
  });

  check(logResponse, {
    'log estruturado: status é 200 OK': (r) => r.status === 200,
  });

  // Pequena pausa entre iterações
  sleep(1);
}

// Função para gerar resumo dos testes (opcional)
export function handleSummary(data) {
  return {
    'summary.json': JSON.stringify(data, null, 2),
  };
}