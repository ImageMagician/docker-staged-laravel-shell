# Laravel Docker Template

A ready-to-use Docker setup for **any** Laravel project. Clone it, drop in a
fresh Laravel install, pick your frontend (**Vue** or **React**), and you have a
containerized dev environment plus a production build — without configuring
Docker, Nginx, or MySQL yourself.

The template is framework-agnostic: the Docker layer doesn't care whether you
choose Vue or React. The only difference between them is which Vite plugin you
install.

## What's included

- **Development stack** — bind-mounted source, live Vite hot-reload, Composer
  and Node available in the containers.
- **Production stack** — a multi-stage build that compiles assets and installs
  dependencies in throwaway stages, shipping a lean PHP-FPM image (no Composer
  or Node) with assets baked into the Nginx image.

| Service | Dev port | Prod port | Role |
|---------|----------|-----------|------|
| nginx   | 8080     | 80        | Web server; serves `public/`, proxies PHP |
| app     | —        | —         | Laravel via PHP-FPM (internal, port 9000) |
| mysql   | 3306     | —         | Database (persisted in a named volume) |
| vite    | 5173     | —         | Vite dev server for HMR (**dev only**) |

## Repository layout

```
.
├── docker-compose.yml           # DEV stack
├── docker-compose.prod.yml      # PROD stack
├── .dockerignore
├── .gitattributes               # forces LF line endings (important for scripts)
├── .gitignore
├── .env.example                 # dev
├── .env.prod.example            # prod
├── docker/
│   ├── php/
│   │   ├── Dockerfile           # dev PHP-FPM image
│   │   ├── Dockerfile.prod      # multi-stage: vendor → assets → runtime → web
│   │   ├── php.ini
│   │   └── entrypoint.prod.sh   # prod startup: rebuilds Laravel caches
│   ├── nginx/
│   │   ├── default.conf         # dev
│   │   └── prod.conf            # prod
│   └── node/
│       └── Dockerfile           # dev Vite image
├── stubs/                       # pre-built files for quick start
│       └── vite.config.base.js  # replacement to support Docker HMR
```

---

## Prerequisites

- Docker + Docker Compose v2 (`docker compose version`)
- Git
- Internet access (to pull images and install dependencies)

---

## Quick start

### 1. Get the template

Either click **"Use this template"** on GitHub, or clone it:

```bash
git clone git@github.com:ImageMagician/laravel-docker-template.git my-project
cd my-project
```

### 2. Create a fresh Laravel app in `src/`
Create a new folder called `src/`
```bash
mkdir src
```

A throwaway Composer container installs the newest Laravel into `src/` — no
local PHP needed. The `-u` flag makes the files owned by you (Linux); the `.`
at the end installs into the current directory rather than a subfolder.

```bash
docker run --rm -u "$(id -u):$(id -g)" \
  -e COMPOSER_HOME=/tmp/composer \
  -v "$(pwd)/src:/app" -w /app composer:2 \
  create-project laravel/laravel .
```

### 3. Point Laravel at the MySQL container

Edit `src/.env`. The default is SQLite — switch it to MySQL, and set
**`DB_HOST=mysql`** (the service name, not `localhost`):

```dotenv
DB_CONNECTION=mysql
DB_HOST=mysql
DB_PORT=3306
DB_DATABASE=laravel
DB_USERNAME=laravel
DB_PASSWORD=secret
```

These environmental variables are called in the `docker-compose.yml`.

### 4. Edit the root .env and .env.prod files
Create the .env and .env.prod files in the root
```bash
cp .env.example .env
cp .env.prod.example .env.prod
```
Add the database credentials in both files.
> The .env.prod file is used for the production build and needs to duplicate the DB_* values for MYSQL_*

### 5. Copy the `vite.config.base.js` file from `stubs/`
Move the `vite.config.base.js` file from `stubs/` to overwrite the existing `src/vite.config.js`
```bash
mv stubs/vite.config.base.js src/vite.config.js
```

### 6. Change `name:` in `docker-compose.yml` and `docker-compose.prod.yml` to match your project name
> Keep them unique with `-dev` or `-prod` suffixes.

### 7. (Optional) Choose a frontend (see 'Frontend setup' below)

Do **one** of the following — see the [Frontend setup](#frontend-setup) section
below for the full details of each. Then continue to step 5.

- **Vue:** install `@vitejs/plugin-vue`, wire `vite.config.base.js` and `app.js`.
- **React:** install `@vitejs/plugin-react`, wire `vite.config.base.js` and `app.jsx`.

### 8. Launch the dev stack

```bash
docker compose up -d
```
Create the APP_KEY for the .env.prod file
```bash
docker compose exec app php artisan key:generate --show
```
Run migrations:
```bash
docker compose exec app php artisan migrate
```

Open **http://localhost:8080**. Vite HMR runs on 5173 automatically.

---

## Frontend setup

Bare Laravel comes Vite-ready but ships no JS framework. Pick one.

### Option A — Vue

Install the plugin (runs in the Node container):

```bash
docker compose run --rm vite npm install vue @vitejs/plugin-vue
```

`src/vite.config.base.js`:

```js
import { defineConfig } from 'vite';
import laravel from 'laravel-vite-plugin';
import vue from '@vitejs/plugin-vue';

export default defineConfig({
  plugins: [
    laravel({
        ...
    }),
    vue({
      template: {
        transformAssetUrls: { base: null, includeAbsolute: false },
      },
    }),
    ...
  ],
  ...
});
```

`src/resources/js/app.js`:

```js
import { createApp } from 'vue';
import App from './App.vue';

createApp(App).mount('#app');
```

`src/resources/js/App.vue`:

```vue
<template>
  <h1>Hello from Vue {{ count }}</h1>
  <button @click="count++">+1</button>
</template>

<script setup>
  import { ref } from 'vue';
  const count = ref(0);
</script>
```

In `src/resources/views/welcome.blade.php`, inside `<body>`:

```blade
<div id="app"></div>
@vite(['resources/css/app.css', 'resources/js/app.js'])
```

### Option B — React

Install the plugin:

```bash
docker compose run --rm vite npm install react react-dom @vitejs/plugin-react
```

React needs a **`.jsx`** entry file. Rename `resources/js/app.js` to `app.jsx`
(any file containing JSX must end in `.jsx`).

`src/vite.config.base.js`:

```js
import { defineConfig } from 'vite';
import laravel from 'laravel-vite-plugin';
import react from '@vitejs/plugin-react';

export default defineConfig({
  plugins: [
    laravel({
      ...
    }),
    react(),
    ... 
  ],
  ...
});
```

`src/resources/js/app.jsx`:

```jsx
import { createRoot } from 'react-dom/client';
import App from './App';

const el = document.getElementById('app');
if (el) createRoot(el).render(<App />);
```

`src/resources/js/App.jsx`:

```jsx
import { useState } from 'react';

export default function App() {
  const [count, setCount] = useState(0);
  return (
          <div>
            <h1>Hello from React {count}</h1>
            <button onClick={() => setCount(count + 1)}>+1</button>
          </div>
  );
}
```

In `src/resources/views/welcome.blade.php`, inside `<body>` — note the
**`@viteReactRefresh`** directive, which must come *before* `@vite` for React
hot-reload to work:

```blade
<div id="app"></div>
@viteReactRefresh
@vite(['resources/css/app.css', 'resources/js/app.jsx'])
```

### Want auth + Inertia out of the box?

Laravel's official **starter kits** ship a complete Vue or React frontend with
Inertia, TypeScript, and authentication already wired up. They're heavier and
more opinionated than the minimal setup above, but save a lot of scaffolding.
See the Laravel documentation (laravel.com) for the current starter-kit
install flow if you'd rather start there instead of steps 2–6.

---

## Production build

Use this to test the production build locally, or as the basis for to deploy the app.
Every command needs the `-f docker-compose.prod.yml` flag.

> Make sure you have created the `.env.prod` file as stated in step 4.

```bash
docker compose -f docker-compose.prod.yml up -d build
```
Right now, migration is built in for single-host staging. But if you scale to multiple replicas, 
go into docker/php/entrypoint.prod.sh and comment out the line that has `php artisan migrate --force`
and run this manually after the "up" command above:
```bash
docker compose -f docker-compose.prod.yml exec app php artisan migrate --force
```

Open **http://localhost** (port 80). Generate an `APP_KEY` for `.env.prod` with
`docker compose exec app php artisan key:generate --show` (dev stack running)
and paste the `base64:...` value in.

> Only run one stack at a time. Bring the other down first.

---

## Switching between stacks

The `-f` flag decides which stack you get: **dev never uses it, prod always does.**

```bash
docker compose up -d                                # dev
docker compose down

docker compose -f docker-compose.prod.yml up -d --build     # prod
docker compose -f docker-compose.prod.yml down
```

---

## Common commands

```bash
docker compose ps                          # status
docker compose logs -f app                 # follow logs
docker compose exec app bash               # shell into the app container
docker compose exec app php artisan <cmd>  # artisan
docker compose exec app composer <cmd>     # composer
docker compose run --rm vite npm <cmd>     # npm (Node container)
```

---

## Troubleshooting

- **`docker compose config -q`** validates the compose file (silent = valid).
- **Restart-looping container** — read logs; look at the *first* error, not the
  last.
- **"Vite manifest not found"** — assets not built. Ensure the `vite` service is
  running (dev), or that the prod build ran.
- **`exec ... no such file or directory` on a script that exists** — Windows
  (CRLF) line endings. Fix: `sed -i 's/\r$//' docker/php/entrypoint.prod.sh`,
  then rebuild. `.gitattributes` prevents recurrence.
- **Edited a baked file, nothing changed (prod)** — prod images copy files at
  build time. Rebuild: `docker compose -f docker-compose.prod.yml build app`.
- **PHP version error** (`requires PHP >= 8.x`) — a newer Laravel may need a
  newer PHP than this template's 8.4. Bump `FROM php:8.4-fpm` in both
  `docker/php/Dockerfile` and `docker/php/Dockerfile.prod` to match.
- **Build errors** if you run into errors like `Permission denied for <MYSQL_USER>` or `APP_KEY missing`, 
  you are most likely dealing with a cached docker volume or image. Try running `docker compose down -v` or
  `docker compose down --rmi local -v` to completely remove the containers and volumes.


---

## Using this template

The template requires a `/src` folder that currently doesn't exist. When you build
a project:

1. Create the `/src` folder.
2. Create your Laravel app in `src/` (Quick start step 2).
3. Your app code is now committable — `vendor/`, `node_modules/`, and `.env`
   stay ignored via `.gitignore`, but your source is tracked.
4. Commit to *your* project's repository.

**Never commit** `.env`, `.env.prod`, `vendor/`, or `node_modules/`.