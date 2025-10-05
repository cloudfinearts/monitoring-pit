const express = require("express");
const client = require("prom-client");

// Create an Express app
const app = express();
// Create a Registry to register the metrics
const register = new client.Registry();

// The metrics we would like to collect:
// 1. A gauge for the current number of active requests
const activeRequests = new client.Gauge({
  name: "active_requests",
  help: "Number of active requests",
  labelNames: ["method", "endpoint"],
});

// 2. A counter for the total number of requests
const totalRequests = new client.Counter({
  name: "app_total_requests",
  help: "Total number of requests",
  labelNames: ["method", "endpoint", "status"],
});

// Register the metrics
register.registerMetric(activeRequests);
register.registerMetric(totalRequests);

client.collectDefaultMetrics({ register });

// Add a middleware that increases activeRequests on request and decreases on response
app.use((req, res, next) => {
  // Increment with labels
  activeRequests.inc({
    method: req.method,
    endpoint: req.path,
  });

  totalRequests.inc({
    method: req.method,
    endpoint: req.path,
  });

  res.on("finish", () => {
    // Decrement with labels for active requests
    activeRequests.dec({
      method: req.method,
      endpoint: req.path,
    });

  });

  next();
});

// Define a route to expose the metrics
app.get("/metrics", async (req, res) => {
  // Allow Prometheus to scrape the metrics
  res.set("Content-Type", register.contentType);
  res.end(await register.metrics());
});

// Define a simple route to simulate app behavior
app.get("/", (req, res) => {
  res.send("Welcome to the Home page of package 1!");
});

// Start the Express server

const port = process.env.PORT || 3001
app.listen(port, () => {
  console.log(`Server listening at http://localhost:${port}`);
});