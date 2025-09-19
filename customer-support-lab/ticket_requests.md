```bash
curl -X POST -H 'Content-Type: application/json' \
  "http://localhost:8080/tickets" \
  -d '{
  "title": "Login fails with 500 error",
  "description": "Users occasionally receive a 500 Internal Server Error when trying to log in through the main portal. Started happening after the latest update."
}'
```

```bash
curl -X POST -H 'Content-Type: application/json' \
  "http://localhost:8080/tickets" \
  -d '{
  "title": "Password reset email not received",
  "description": "Several users report not receiving password reset emails. We’ve confirmed the messages aren’t in spam, and our mail server appears to be up. Check backend API log for errors."
}
'
```

```bash
curl -X POST -H 'Content-Type: application/json' \
  "http://localhost:8080/tickets" \
  -d '{
  "title": "Slow response from user dashboard",
  "description": "The dashboard is taking 10–15 seconds to load user data, even for lightweight accounts. This is causing complaints from support."
}
'
```

```bash
curl -X POST -H 'Content-Type: application/json' \
  "http://localhost:8080/tickets" \
  -d '{
  "title": "Login session times out too quickly",
  "description": "Users are being logged out after just 5 minutes of inactivity, which is too aggressive. We’d like to increase the session timeout to 30 minutes."
}
'
```

```bash
curl -X POST -H 'Content-Type: application/json' \
  "http://localhost:8080/tickets" \
  -d '{
  "title": "Cannot create new users via API",
  "description": "The API endpoint for user creation sometimes returns a 500 Internal Sever Error despite valid credentials and permissions. This is blocking automation scripts."
}
'
```