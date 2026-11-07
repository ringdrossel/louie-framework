#!/usr/bin/env python3
"""Live progress filter for louie-run.sh.

Reads a harness's streaming JSON-lines output on stdin and prints a compact,
human-readable activity line per interesting event to stdout. Everything else
is dropped silently; the raw stream is already being tee'd to the run log.

Harness-agnostic on purpose: instead of one parser per tool, it walks every
JSON object and reacts to a few shapes that the streaming formats share or
resemble closely:

  * text the agent says      {"type":"text","text":...}             (Claude Code,
                             — only inside events the agent emits; text inside
                             "user" events (tool results, subagent handbacks fed
                             back to the agent) is labelled handback:/error: or dropped
                             {"type":"agent_message","text":...}    Anthropic-style)
                             {"type":"message", "content"/"text"}   (Codex items, Gemini)
  * a tool being used        {"type":"tool_use","name":...,"input":{...}}
                             {"type":"command_execution","command":...}
                             {"type":"file_change", ...}
  * one-line progress notes  {"type":"system","subtype":"task_summary","detail":...}
  * the final result         {"type":"result", ...}

Lines that are not JSON, or JSON that matches nothing, print nothing. The
filter never fails the run: any exception on a line is swallowed.

Usage (as wired by louie-run.sh):  <harness> | tee -a run.log | python3 louie-run-progress.py [prefix]
"""
import json
import sys
import time

PREFIX = sys.argv[1] if len(sys.argv) > 1 else ""
MAX = 240


def out(kind, text):
    text = " ".join(str(text).split())
    if len(text) > MAX:
        text = text[: MAX - 1] + "…"
    stamp = time.strftime("%H:%M:%S")
    sys.stdout.write(f"{stamp} {PREFIX}{kind} {text}\n")
    sys.stdout.flush()


def summarize_input(inp):
    if not isinstance(inp, dict):
        return ""
    for key in ("description", "command", "file_path", "path", "pattern", "query", "prompt", "url"):
        val = inp.get(key)
        if isinstance(val, str) and val.strip():
            return val
    return ""


NOISE = ("SubagentHandback", "agentId:", "Read it there; it is not repeated here")


def walk(node, seen_text, inbound=False):
    """Yield (kind, text) for every recognised shape under node.

    inbound=True while inside a "user" event: that content flows INTO the agent
    (tool results, subagent reports), so it is not something the agent said.
    """
    if isinstance(node, list):
        for item in node:
            yield from walk(item, seen_text, inbound)
        return
    if not isinstance(node, dict):
        return

    t = node.get("type")
    if t == "user":
        inbound = True

    if t == "tool_result":
        # Tool output is not progress — unless it failed.
        if node.get("is_error"):
            body = node.get("content")
            if isinstance(body, list):
                body = " ".join(b.get("text", "") for b in body if isinstance(b, dict))
            yield ("error:", str(body or "tool call failed"))
        return

    if t == "text" and isinstance(node.get("text"), str):
        text = node["text"]
        if inbound:
            if any(marker in text for marker in NOISE):
                return
            yield ("handback:", text)
        else:
            yield ("says:", text)
    elif t in ("agent_message", "message"):
        body = node.get("text") or node.get("content")
        if isinstance(body, str) and body.strip():
            yield ("says:", body)
    elif t == "tool_use" and isinstance(node.get("name"), str):
        detail = summarize_input(node.get("input"))
        yield ("tool:", f"{node['name']}" + (f" — {detail}" if detail else ""))
    elif t == "command_execution" and isinstance(node.get("command"), str):
        yield ("tool:", f"shell — {node['command']}")
    elif t == "file_change":
        changes = node.get("changes") or node.get("path") or ""
        if isinstance(changes, list):
            changes = ", ".join(str(c.get("path", c)) if isinstance(c, dict) else str(c) for c in changes)
        yield ("edit:", str(changes))
    elif t == "system" and node.get("subtype") == "task_summary" and node.get("detail"):
        yield ("note:", node["detail"])
    elif t == "system" and node.get("subtype") == "init":
        yield ("session", f"started (id {str(node.get('session_id', ''))[:8]})")
    elif t == "result" or ("total_cost_usd" in node and "num_turns" in node):
        turns = node.get("num_turns")
        cost = node.get("total_cost_usd")
        err = node.get("is_error")
        bits = []
        if turns is not None:
            bits.append(f"{turns} turns")
        if cost is not None:
            try:
                bits.append(f"~${float(cost):.2f}")
            except (TypeError, ValueError):
                pass
        if err:
            bits.append("ended with error")
        yield ("session", "finished" + (f" ({', '.join(bits)})" if bits else ""))

    # Recurse into nested message/content/item structures (but not back into
    # tool inputs or results, which can be huge and are not progress).
    for key in ("message", "content", "item", "items", "value", "data"):
        child = node.get(key)
        if isinstance(child, (dict, list)):
            yield from walk(child, seen_text, inbound)


def main():
    seen_text = set()
    for raw in sys.stdin:
        line = raw.strip()
        if not line or line[0] not in "{[":
            continue
        try:
            obj = json.loads(line)
        except ValueError:
            continue
        try:
            for kind, text in walk(obj, seen_text):
                if kind in ("says:", "handback:"):
                    # Streaming formats often repeat the same text block across
                    # events (partial + final); print each distinct text once.
                    key = text.strip()[:200]
                    if key in seen_text:
                        continue
                    seen_text.add(key)
                out(kind, text)
        except Exception:  # never let a weird event kill the progress view
            continue


if __name__ == "__main__":
    main()
