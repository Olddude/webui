# webui

OpenAI compatible chat bot web client

## Requirements

- node 20+
- openai compatible backend which should implement the following endpoints:

  ```text
  GET  /v1/models
  POST /v1/chat/completions
  POST /v1/completions
  POST /v1/embeddings
  ```

## Development

- Install dependencies by running `npm install`
- Run OpenAI compatible backend on port `3004` (See [vite.config.ts](./vite.config.ts) for /v1 proxy configuration.)
- Start the dev server by running `npm run dev`
- Open in your browser `http://localhost:5173`

## License

ISC

## Reset Git History

### Squash local HEAD history

```sh
# DO THIS ONLY WHEN FULLY UNDERSTOOD WHAT IT DOES
# THIS WILL SQUASH THE LOCAL MASTER INTO 1 COMMIT
# THIS IS IRREVERSIBLE AND WILL WIPE THE HISTORY LOCALY
git reset $(git commit-tree HEAD^{tree} -m "0.1.0") && git tag 0.1.0
```

### Force push remote HEAD history

```sh
# DO THIS ONLY WHEN FULLY UNDERSTOOD WHAT IT DOES
# THIS WILL FORCE PUSH THE LOCAL SQUASHED HISTORY INTO THE REMOTE
# THIS IS IRREVERSIBLE AND WILL WIPE THE HISTORY IN THE REMOTE
git push origin HEAD --force --tags
```
