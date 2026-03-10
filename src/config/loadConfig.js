const fs = require("fs");
const path = require("path");
const { createLogger } = require("../utils/logger");

const CONFIG_PATH = path.resolve(__dirname, "../../data/config.json");
const logger = createLogger("config");

const DEFAULT_CONFIG = {
  headless: true,
  thread: 2,
  browser_type: "chromium",
  api: {
    enabled: true,
    host: "0.0.0.0",
    port: 8000
  }
};

function mergeConfig(config = {}) {
  return {
    ...DEFAULT_CONFIG,
    ...config,
    api: {
      ...DEFAULT_CONFIG.api,
      ...(config.api || {})
    }
  };
}

function loadConfig() {
  try {
    const raw = fs.readFileSync(CONFIG_PATH, "utf8");
    const parsed = JSON.parse(raw);
    logger.success(`loaded ${CONFIG_PATH}`);
    return mergeConfig(parsed);
  } catch (error) {
    if (error.code === "ENOENT") {
      logger.warn("config not found, using defaults");
    } else {
      logger.warn(`config invalid: ${error.message}`);
    }

    return { ...DEFAULT_CONFIG, api: { ...DEFAULT_CONFIG.api } };
  }
}

module.exports = {
  loadConfig
};
