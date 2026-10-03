#!/usr/bin/env python3

import json
import os
import sys
import urllib.error
import urllib.request


def env(name: str, default: str = "-") -> str:
    value = os.getenv(name)
    return value if value else default


def field(name: str, value: str, inline: bool = True) -> dict:
    return {
        "name": name,
        "value": value,
        "inline": inline,
    }


def build_payload(status: str) -> dict:
    success = status == "success"

    if success:
        title = "✅ CI Pipeline Succeeded"
        description = "Jenkins pipeline completed successfully."
        color = 3066993
    else:
        title = "❌ CI Pipeline Failed"
        description = "Jenkins pipeline encountered an error."
        color = 15158332

    fields = [
        field("📦 Job", f"`{env('JOB_NAME')}`"),
        field("🔢 Build", f"`#{env('BUILD_NUMBER')}`"),
        field("🌿 Branch", f"`{env('BRANCH_NAME')}`"),
        field("⚙️ CI Mode", f"`{env('CI_MODE')}`"),
        field("🔖 Commit", f"`{env('COMMIT_SHA')}`"),
    ]

    image_name = os.getenv("IMAGE_NAME")

    if image_name:
        fields.append(
            field(
                "🐳 Image",
                f"`{image_name}`",
                False,
            )
        )

    gitops_commit = os.getenv("GITOPS_COMMIT")

    if gitops_commit:
        fields.append(
            field(
                "🚀 GitOps Commit",
                f"`{gitops_commit}`",
                False,
            )
        )

    build_url = os.getenv("BUILD_URL")

    if build_url:
        fields.append(
            field(
                "🔗 Jenkins Build",
                build_url,
                False,
            )
        )

    return {
        "username": "Jenkins CI",
        "embeds": [
            {
                "title": title,
                "description": description,
                "color": color,
                "fields": fields,
                "footer": {
                    "text": "TaskFlow CI • Jenkins"
                },
            }
        ],
    }


def send_notification(status: str) -> None:
    webhook_url = os.getenv("DISCORD_WEBHOOK_URL")

    if not webhook_url:
        raise RuntimeError(
            "DISCORD_WEBHOOK_URL environment variable is not set."
        )

    payload = build_payload(status)

    request = urllib.request.Request(
        webhook_url,
        data=json.dumps(payload).encode("utf-8"),
        headers={
            "Content-Type": "application/json",
            "User-Agent": "TaskFlow-Jenkins-CI",
        },
        method="POST",
    )

    try:
        with urllib.request.urlopen(request, timeout=10) as response:
            if response.status not in (200, 204):
                raise RuntimeError(
                    f"Discord returned HTTP {response.status}"
                )

    except urllib.error.HTTPError as exc:
        body = exc.read().decode("utf-8", errors="replace")

        raise RuntimeError(
            f"Discord webhook failed: HTTP {exc.code}: {body}"
        ) from exc

    except urllib.error.URLError as exc:
        raise RuntimeError(
            f"Unable to connect to Discord: {exc.reason}"
        ) from exc


def main() -> None:
    if len(sys.argv) != 2:
        print(
            f"Usage: {sys.argv[0]} <success|failure>",
            file=sys.stderr,
        )
        sys.exit(2)

    status = sys.argv[1].lower()

    if status not in {"success", "failure"}:
        print(
            f"Unsupported status: {status}",
            file=sys.stderr,
        )
        sys.exit(2)

    send_notification(status)

    print(f"Discord notification sent: {status}")


if __name__ == "__main__":
    main()