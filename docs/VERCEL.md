# Vercel deployment

Denti's Web build is produced by the existing GitHub Actions workflow with Godot 4.7.2. The same compiled `build/web` artifact can optionally be deployed to Vercel, so Vercel does not need to download and install Godot or its export templates for every deployment.

## One-time setup

1. Create a Vercel project for Denti.
2. Install/login to the Vercel CLI locally if needed:

   ```bash
   npm install --global vercel
   vercel login
   ```

3. From the Denti repository, link the project:

   ```bash
   vercel link
   ```

4. Read `.vercel/project.json`. It contains `orgId` and `projectId`.
5. Create a Vercel access token in your Vercel account settings.
6. In GitHub, open the Denti repository and go to **Settings -> Secrets and variables -> Actions**. Add these repository secrets:

   - `VERCEL_TOKEN`: the Vercel access token
   - `VERCEL_ORG_ID`: the `orgId` from `.vercel/project.json`
   - `VERCEL_PROJECT_ID`: the `projectId` from `.vercel/project.json`

The local `.vercel/` folder is intentionally ignored by Git.

## Deployment flow

On every push to `main`:

1. GitHub Actions imports the project and runs the tests.
2. Godot exports the `Web` preset to `build/web/index.html`.
3. The build is deployed to GitHub Pages as before.
4. If all three Vercel secrets exist, the same build artifact is placed in Vercel's Build Output API static directory and deployed with `vercel deploy --prebuilt --prod`.

No Godot installation is required inside Vercel itself.

## Manual run

The workflow also supports **Actions -> Deploy Denti Web -> Run workflow**.

If the Vercel secrets are not configured, the Vercel job prints a message and exits successfully while GitHub Pages continues to work normally.
