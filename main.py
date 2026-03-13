"""Cloud Function entry-point for shellRunner."""
import os, json
import functions_framework

@functions_framework.http
def run(request):
    body = request.get_json(silent=True) or {}
    command = body.get("command", "")
    if command == "make_zip":
        return json.dumps({"status": "ok", "action": "make_zip"})
    elif command.startswith("email "):
        recipient = command.split(" ", 1)[1]
        return json.dumps({"status": "ok", "action": "email", "to": recipient})
    elif command == "push_github":
        return json.dumps({"status": "ok", "action": "push_github"})
    else:
        return json.dumps({"echo": command})
