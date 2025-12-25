/**
 * x402 Protocol Gateway
 * Hono Cloudflare Worker
 *
 * Handles HTTP 402 payment challenges for paid API access.
 */

import { Hono } from "hono";
import { cors } from "hono/cors";
import { logger } from "hono/logger";
import { createPublicClient, http, parseUnits, formatUnits } from "viem";
import { base } from "viem/chains";

// Types
interface Env {
  PAYMENT_RECIPIENT: string;
  USDC_ADDRESS: string;
  MIN_PAYMENT: string;
}

interface PaymentHeader {
  version: string;
  network: string;
  token: string;
  amount: string;
  recipient: string;
  expires: number;
  signature: string;
}

interface PaymentRequest {
  network: string;
  token: string;
  amount: string;
  recipient: string;
}

// Constants
const USDC_ADDRESS = "0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913"; // Base USDC
const DEFAULT_PAYMENT = "0.01"; // $0.01 default

// Create Hono app
const app = new Hono<{ Bindings: Env }>();

// Middleware
app.use("*", cors());
app.use("*", logger());

// ==========================================================================
// HELPERS
// ==========================================================================

/**
 * Parse x402 payment header
 */
function parsePaymentHeader(header: string): PaymentHeader | null {
  try {
    const parts = header.replace("x402 ", "").split(",");
    const payment: Partial<PaymentHeader> = {};

    for (const part of parts) {
      const [key, value] = part.trim().split("=");
      if (key && value) {
        if (key === "expires") {
          payment[key] = parseInt(value, 10);
        } else {
          (payment as any)[key] = value;
        }
      }
    }

    if (
      payment.version &&
      payment.network &&
      payment.token &&
      payment.amount &&
      payment.recipient &&
      payment.expires &&
      payment.signature
    ) {
      return payment as PaymentHeader;
    }
  } catch (e) {
    console.error("Failed to parse payment header:", e);
  }
  return null;
}

/**
 * Verify payment signature
 */
async function verifyPayment(payment: PaymentHeader): Promise<boolean> {
  // In production, verify the signature using viem
  // const message = `${payment.network}:${payment.token}:${payment.amount}:${payment.recipient}:${payment.expires}`;
  // const isValid = await verifyMessage({ address, message, signature: payment.signature });

  // Check expiration
  if (payment.expires < Math.floor(Date.now() / 1000)) {
    return false;
  }

  // For now, accept any signed payment
  return true;
}

/**
 * Create payment request response
 */
function createPaymentRequest(
  c: any,
  amount: string = DEFAULT_PAYMENT
): Response {
  const recipient = c.env.PAYMENT_RECIPIENT || "0x0000000000000000000000000000000000000000";

  const paymentRequest: PaymentRequest = {
    network: "base",
    token: "USDC",
    amount,
    recipient,
  };

  return c.json(
    {
      error: "Payment Required",
      payment_request: paymentRequest,
    },
    402,
    {
      "X-Payment-Request": `x402 network=base,token=USDC,amount=${amount},recipient=${recipient}`,
    }
  );
}

// ==========================================================================
// ROUTES
// ==========================================================================

/**
 * Health check
 */
app.get("/", (c) => {
  return c.json({
    service: "x402-gateway",
    version: "1.0.0",
    status: "healthy",
  });
});

/**
 * Free data endpoint
 */
app.get("/data/free", (c) => {
  return c.json({
    data: "This is free data!",
    timestamp: new Date().toISOString(),
  });
});

/**
 * Paid data endpoint
 */
app.get("/data/:id", async (c) => {
  const dataId = c.req.param("id");
  const paymentHeader = c.req.header("X-Payment");

  // Check for payment
  if (!paymentHeader) {
    return createPaymentRequest(c);
  }

  // Parse and verify payment
  const payment = parsePaymentHeader(paymentHeader);
  if (!payment) {
    return c.json({ error: "Invalid payment header" }, 400);
  }

  const isValid = await verifyPayment(payment);
  if (!isValid) {
    return createPaymentRequest(c);
  }

  // Return paid data
  return c.json({
    data: {
      id: dataId,
      content: `Premium data for ${dataId}`,
      accessed_at: new Date().toISOString(),
    },
    payment: {
      amount: payment.amount,
      token: payment.token,
    },
  });
});

/**
 * Create invite
 */
app.post("/invite", async (c) => {
  const body = await c.req.json();
  const { message, uses } = body;

  // Generate invite code
  const inviteCode = crypto.randomUUID().slice(0, 8);

  return c.json({
    url: `https://echo.xyz/invite/${inviteCode}`,
    code: inviteCode,
    message,
    uses,
    created_at: new Date().toISOString(),
  });
});

/**
 * Send tip
 */
app.post("/tip", async (c) => {
  const paymentHeader = c.req.header("X-Payment");

  if (!paymentHeader) {
    return createPaymentRequest(c);
  }

  const payment = parsePaymentHeader(paymentHeader);
  if (!payment) {
    return c.json({ error: "Invalid payment header" }, 400);
  }

  const isValid = await verifyPayment(payment);
  if (!isValid) {
    return createPaymentRequest(c);
  }

  const body = await c.req.json();

  return c.json({
    status: "success",
    recipient: body.recipient,
    amount: payment.amount,
    message: body.message,
    tx_hash: `0x${crypto.randomUUID().replace(/-/g, "")}`,
  });
});

/**
 * Query agent
 */
app.post("/query", async (c) => {
  const paymentHeader = c.req.header("X-Payment");

  // Queries cost more
  if (!paymentHeader) {
    return createPaymentRequest(c, "0.05");
  }

  const payment = parsePaymentHeader(paymentHeader);
  if (!payment || !(await verifyPayment(payment))) {
    return createPaymentRequest(c, "0.05");
  }

  const body = await c.req.json();
  const { query } = body;

  // In production, forward to agent
  return c.json({
    query,
    response: `Response to: ${query}`,
    tokens_used: 150,
    cost: payment.amount,
  });
});

/**
 * Get price feed
 */
app.get("/price/:symbol", async (c) => {
  const symbol = c.req.param("symbol");

  // Price feeds are free (for now)
  const prices: Record<string, number> = {
    "ETH-USD": 2500,
    "BTC-USD": 45000,
    "USDC-USD": 1.0,
  };

  const price = prices[symbol.toUpperCase()];
  if (!price) {
    return c.json({ error: "Unknown symbol" }, 404);
  }

  return c.json({
    symbol,
    price,
    timestamp: new Date().toISOString(),
    source: "x402-gateway",
  });
});

// ==========================================================================
// EXPORT
// ==========================================================================

export default app;
