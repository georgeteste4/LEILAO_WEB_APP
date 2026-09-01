# 📱 App Leilão de Imóveis — Standalone React Native APK

Aplicativo mobile e web construído em **React Native / Expo** com **banco de dados SQLite interno**, motores de extração/scraping nativos em TypeScript, **Painel de Configurações com Atualizador Automático de APK** e **Compilação Automática via GitHub Actions**.

---

## 🚀 Como Executar Localmente

1. Entre na pasta do aplicativo:
   ```bash
   cd app_leilao
   ```

2. Instale as dependências:
   ```bash
   npm install
   ```

3. Inicie o app no navegador web ou emulador/celular:
   ```bash
   npm run start
   # ou para web direto:
   npm run web
   ```

---

## 📦 Como Compilar o APK no GitHub

1. Faça push para a branch `main`:
   ```bash
   git add .
   git commit -m "update app"
   git push origin main
   ```
2. O **GitHub Actions** compilará o APK automaticamente em `.github/workflows/build-apk.yml`.
3. Para publicar uma nova versão que o **Atualizador In-App** detecta:
   ```bash
   git tag v1.0.1
   git push origin v1.0.1
   ```
