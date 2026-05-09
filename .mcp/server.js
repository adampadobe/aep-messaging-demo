#!/usr/bin/env node
/**
 * AEP Messaging iOS — local MCP server
 *
 * Tools:
 *   deploy_to_device     — build + install app to a named device
 *   list_devices         — show all connected iOS devices + their pairing status
 *   open_in_xcode        — open the workspace in Xcode
 *   git_commit           — stage files and commit with a Conventional Commits message
 *   git_status           — show working-tree status and last 5 commits
 *   assurance_deep_link  — generate an Assurance deep-link URL for a given session ID
 */

import { McpServer } from "@modelcontextprotocol/sdk/server/mcp.js";
import { StdioServerTransport } from "@modelcontextprotocol/sdk/server/stdio.js";
import { z } from "zod";
import { exec, spawn } from "child_process";
import { promisify } from "util";
import path from "path";
import { fileURLToPath } from "url";

const execAsync = promisify(exec);
const __dirname = path.dirname(fileURLToPath(import.meta.url));
const REPO_ROOT = path.resolve(__dirname, "..");

// ---------------------------------------------------------------------------
// Known devices — update UDIDs here when adding new devices
// ---------------------------------------------------------------------------
const DEVICES = {
  dev: {
    label: "Adam Dev iPhone (iPhone 15)",
    udid: "227B97BD-AC99-592B-BEA0-68EF9DA0EA53",
    ecid: "47288941103661241645408602224153721911",
  },
  work: {
    label: "Adam Work iPhone (iPhone 17e)",
    udid: "6ABB0313-93E9-54D5-BD98-9C5FABCE48D5",
    ecid: "72741576365611900757159622710055496241",
  },
};

const WORKSPACE = path.join(REPO_ROOT, "AEPMessaging.xcworkspace");
const SCHEME = "MessagingDemoAppSwiftUI";
const BUNDLE_ID = "com.adampadobe.aep-messaging-demo";
const TEAM_ID = "ZWRQX72TY4";

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

function run(cmd, opts = {}) {
  return execAsync(cmd, { cwd: REPO_ROOT, maxBuffer: 10 * 1024 * 1024, ...opts });
}

function spawnStream(cmd, args, opts = {}) {
  return new Promise((resolve, reject) => {
    const lines = [];
    const child = spawn(cmd, args, {
      cwd: REPO_ROOT,
      stdio: ["ignore", "pipe", "pipe"],
      ...opts,
    });
    child.stdout.on("data", (d) => lines.push(d.toString()));
    child.stderr.on("data", (d) => lines.push(d.toString()));
    child.on("close", (code) =>
      code === 0
        ? resolve(lines.join(""))
        : reject(new Error(`exit ${code}\n${lines.join("")}`))
    );
  });
}

// ---------------------------------------------------------------------------
// MCP server
// ---------------------------------------------------------------------------

const server = new McpServer({
  name: "aep-messaging-xcode-mcp",
  version: "1.0.0",
});

// ── deploy_to_device ─────────────────────────────────────────────────────────
server.tool(
  "deploy_to_device",
  "Build and install MessagingDemoAppSwiftUI to a named device ('dev' or 'work'). " +
    "Equivalent to xcodebuild build install with -allowProvisioningUpdates.",
  {
    device: z
      .enum(["dev", "work"])
      .describe("Which device to target: 'dev' (iPhone 15) or 'work' (iPhone 17e)"),
    configuration: z
      .enum(["Debug", "Release"])
      .optional()
      .default("Debug")
      .describe("Build configuration (default: Debug)"),
  },
  async ({ device, configuration }) => {
    const d = DEVICES[device];
    const args = [
      "xcodebuild",
      "-workspace", WORKSPACE,
      "-scheme", SCHEME,
      "-destination", `platform=iOS,id=${d.udid}`,
      "-configuration", configuration,
      "-allowProvisioningUpdates",
      "-allowProvisioningDeviceRegistration",
      "build",
      "install",
    ];

    let output = "";
    try {
      output = await spawnStream(args[0], args.slice(1));
    } catch (err) {
      output = err.message;
    }

    const succeeded = output.includes("BUILD SUCCEEDED") && output.includes("INSTALL SUCCEEDED");
    const buildFailed = output.includes("BUILD FAILED");

    // Extract only errors + final result lines to keep response short
    const summary = output
      .split("\n")
      .filter((l) =>
        /error:|BUILD SUCCEEDED|BUILD FAILED|INSTALL SUCCEEDED|INSTALL FAILED/.test(l)
      )
      .filter((l) => !/warning/.test(l))
      .slice(-20)
      .join("\n");

    if (succeeded) {
      return {
        content: [
          {
            type: "text",
            text:
              `✅ Deployed to ${d.label}\n` +
              `   UDID: ${d.udid}\n` +
              `   Configuration: ${configuration}\n\n` +
              `Next: kill and cold-launch the app, then check Assurance for application.launch.`,
          },
        ],
      };
    }

    return {
      content: [
        {
          type: "text",
          text: `❌ Deploy to ${d.label} failed.\n\n${summary}`,
        },
      ],
    };
  }
);

// ── list_devices ─────────────────────────────────────────────────────────────
server.tool(
  "list_devices",
  "List all connected iOS devices and their pairing/availability status.",
  {},
  async () => {
    let raw = "";
    try {
      ({ stdout: raw } = await run("xcrun devicectl list devices 2>&1"));
    } catch (err) {
      raw = err.message;
    }

    const known = Object.entries(DEVICES)
      .map(([key, d]) => `  ${key.padEnd(5)} | ${d.label}\n        UDID: ${d.udid}\n        ECID: ${d.ecid}`)
      .join("\n");

    return {
      content: [
        {
          type: "text",
          text: `Known devices for this repo:\n${known}\n\n--- devicectl output ---\n${raw.trim()}`,
        },
      ],
    };
  }
);

// ── open_in_xcode ─────────────────────────────────────────────────────────────
server.tool(
  "open_in_xcode",
  "Open the AEPMessaging workspace in Xcode.",
  {},
  async () => {
    await run(`open "${WORKSPACE}"`);
    return {
      content: [{ type: "text", text: `Opened ${WORKSPACE} in Xcode.` }],
    };
  }
);

// ── git_status ────────────────────────────────────────────────────────────────
server.tool(
  "git_status",
  "Show working-tree status and the last 8 commits in the repo.",
  {},
  async () => {
    const [{ stdout: status }, { stdout: log }] = await Promise.all([
      run("git status"),
      run("git log --oneline -8"),
    ]);
    return {
      content: [
        {
          type: "text",
          text: `--- git status ---\n${status.trim()}\n\n--- last 8 commits ---\n${log.trim()}`,
        },
      ],
    };
  }
);

// ── git_commit ────────────────────────────────────────────────────────────────
server.tool(
  "git_commit",
  "Stage specified files (or all modified tracked files if none given) and create a commit. " +
    "Message should follow Conventional Commits: 'feat(demo): ...' / 'fix(sdk): ...' / 'chore: ...'",
  {
    message: z
      .string()
      .min(10)
      .describe(
        "Commit message. Use Conventional Commits format: type(scope): summary. " +
          "A Co-Authored-By trailer will be appended automatically."
      ),
    files: z
      .array(z.string())
      .optional()
      .describe(
        "Specific files to stage. If omitted, all modified tracked files are staged (git add -u)."
      ),
  },
  async ({ message, files }) => {
    // Stage
    if (files && files.length > 0) {
      const quoted = files.map((f) => `"${f}"`).join(" ");
      await run(`git add ${quoted}`);
    } else {
      await run("git add -u");
    }

    const fullMessage =
      message.trimEnd() +
      "\n\nCo-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>";

    // Commit
    try {
      const { stdout } = await run(
        `git commit -m ${JSON.stringify(fullMessage)}`
      );
      const hash = stdout.match(/\[main ([0-9a-f]+)\]/)?.[1] ?? "?";
      return {
        content: [
          {
            type: "text",
            text: `✅ Committed: ${hash}\n${stdout.trim()}`,
          },
        ],
      };
    } catch (err) {
      return {
        content: [{ type: "text", text: `❌ Commit failed:\n${err.message}` }],
      };
    }
  }
);

// ── assurance_deep_link ───────────────────────────────────────────────────────
server.tool(
  "assurance_deep_link",
  "Generate the Assurance deep-link URL for a given session ID so you can paste it into " +
    "Constants.swift or QR-scan it with the app.",
  {
    sessionId: z
      .string()
      .uuid()
      .describe("Assurance session UUID from experience.adobe.com/assurance"),
  },
  ({ sessionId }) => {
    const url = `messagingdemo://?adb_validation_sessionid=${sessionId}`;
    return {
      content: [
        {
          type: "text",
          text:
            `Deep link: ${url}\n\n` +
            `To auto-connect on launch, paste this into Constants.swift:\n` +
            `  static let assuranceURL = "${url}"`,
        },
      ],
    };
  }
);

// ---------------------------------------------------------------------------
// Start
// ---------------------------------------------------------------------------

const transport = new StdioServerTransport();
await server.connect(transport);
