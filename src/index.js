const { loadConfig } = require("./config/loadConfig");
const { createServer } = require("./server/createServer");
const { TurnstileSolver } = require("./solver/TurnstileSolver");
const { createLogger } = require("./utils/logger");

const config = loadConfig();
const logger = createLogger("app");
let solver;
let server;

function showConfig() {
  logger.info("using config");
  console.log(JSON.stringify(config, null, 2));
}

async function runCli() {
  logger.info("cli mode");
  console.log(JSON.stringify(solver.getStatus(), null, 2));
  console.log("await solver.solve('https://example.com', '0x4AAAAAAAB...')");
  console.log("await solver.solve('https://example.com', '0x4AAAAAAAB...', 'login', 'user123')");

  await new Promise(() => {});
}

async function closeServer() {
  if (server) {
    await new Promise((resolve) => {
      server.close(() => resolve());
    });
  }
}

async function shutdown(code) {
  await closeServer();
  if (solver) {
    await solver.cleanup();
  }

  process.exit(code);
}

async function main() {
  showConfig();

  solver = new TurnstileSolver({
    headless: config.headless,
    thread: config.thread,
    browser_type: config.browser_type
  });

  await solver.initialize();

  if (config.api.enabled) {
    const serverApp = createServer({ config, solver });
    await new Promise((resolve) => {
      server = serverApp.listen(config.api.port, config.api.host, () => {
        logger.success(`api ready on ${config.api.host}:${config.api.port}`);
        resolve();
      });
    });
    return;
  }

  logger.info("start cli mode");
  await runCli();
}

process.on("SIGINT", async () => {
  await shutdown(0);
});

process.on("SIGTERM", async () => {
  await shutdown(0);
});

main().catch(async (error) => {
  logger.error(`fatal: ${error.message}`);
  await shutdown(1);
});
