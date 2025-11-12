// bridge/server.js (from research, with allowlist tightened)
const express = require("express");
const fs = require("fs").promises;
const path = require("path");
const { exec } = require("child_process");
const crypto = require("crypto");

const app = express();
app.use(express.json());

// Signature verification (HMAC-SHA256)
const SECRET = process.env.GPT_BRIDGE_SECRET;

function verifySignature(payload, signature) {
  if (!SECRET) return false;
  const hmac = crypto.createHmac("sha256", SECRET);
  const expected = hmac.update(JSON.stringify(payload)).digest("hex");
  try {
    return crypto.timingSafeEqual(
      Buffer.from(signature || "", "utf8"),
      Buffer.from(expected, "utf8")
    );
  } catch {
    return false;
  }
}

// Endpoint for GPT to POST code
app.post("/api/code-patch", async (req, res) => {
  const { signature } = req.headers;
  const staticKey = req.headers["x-bridge-key"];
  const { filePath, content, operation } = req.body || {};

  // AuthN: EITHER HMAC signature OR static dev key
  const authOK = (staticKey && staticKey === SECRET) || verifySignature(req.body, signature);
  if (!authOK) {
    return res.status(401).json({ error: "Invalid signature" });
  }

  try {
    // ALLOWLIST: only under src/gptmodules/
    if (typeof filePath !== "string" || !filePath.startsWith("src/gptmodules/")) {
      return res.status(403).json({ error: "Path not allowed" });
    }

    const fullPath = path.join(__dirname, "..", filePath);

    if (operation === "write") {
      await fs.mkdir(path.dirname(fullPath), { recursive: true });
      await fs.writeFile(fullPath, content ?? "", "utf8");
    } else if (operation === "delete") {
      await fs.unlink(fullPath);
    } else {
      return res.status(400).json({ error: "Unknown operation" });
    }

    // Optional format step (StyLua) — ignore failures
    exec(`stylua ${fullPath}`, (err) => {
      if (err) console.warn("Lint warning:", err?.message || String(err));
    });

    res.json({ success: true, path: filePath });
  } catch (error) {
    console.error("Patch error:", error);
    res.status(500).json({ error: error.message });
  }
});

app.listen(3000, () => console.log("Bridge listening on :3000"));
