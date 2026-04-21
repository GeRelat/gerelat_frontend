# GeRelat — Frontend

Interface web do sistema GeRelat, uma plataforma para geração semi-automática de relatórios institucionais.

Desenvolvido com **Flutter Web** e **Dart**.

---

## Pré-requisitos

Antes de rodar o projeto, certifique-se de ter instalado:

| Ferramenta | Versão mínima | Download |
|---|---|---|
| Flutter SDK | 3.11.5 | [flutter.dev](https://flutter.dev/docs/get-started/install) |
| Dart SDK | 3.11.5 | Incluído no Flutter |
| Google Chrome | qualquer | [google.com/chrome](https://www.google.com/chrome/) |
| Git | qualquer | [git-scm.com](https://git-scm.com/) |

---

## Instalação

**1. Clone o repositório**

```bash
git clone <url-do-repositório>
cd gerelat_frontend
```

**2. Instale as dependências**

```bash
flutter pub get
```

**3. Verifique o ambiente**

```bash
flutter doctor
```

Os itens Flutter, Chrome e a toolchain do sistema operacional devem estar marcados com ✓.

---

## Rodando o projeto

```bash
flutter run -d chrome
```

O app abre automaticamente no Chrome. Com o servidor rodando, use `r` no terminal para **hot reload** (atualiza a tela sem reiniciar).

---

## Estrutura de pastas

```
lib/
├── main.dart                          # Ponto de entrada da aplicação
│
├── nucleo/
│   ├── componentes/
│   │   └── barra_topo.dart            # AppBar compartilhada entre páginas
│   ├── servicos/
│   │   └── servico_autenticacao.dart  # Requisições HTTP para a gerelat-api
│   └── temas/
│       ├── cores.dart                 # Paleta de cores do design system
│       └── tipografia.dart            # Estilos de texto (Poppins + Roboto)
│
└── paginas/
    ├── login/
    │   ├── pagina_login.dart
    │   └── componentes/
    │       ├── painel_esquerdo.dart   # Painel azul com logo e ilustração
    │       └── painel_direito.dart    # Formulário de e-mail e senha
    ├── cadastro/
    │   ├── pagina_cadastro.dart
    │   └── componentes/
    │       └── formulario_cadastro.dart
    ├── sucesso_cadastro/
    │   └── pagina_sucesso_cadastro.dart
    └── recuperar_senha/
        ├── pagina_recuperar_senha.dart
        ├── pagina_email_enviado.dart
        └── pagina_nova_senha.dart
```

---

## Design System

### Cores

Todas as cores ficam centralizadas em `lib/nucleo/temas/cores.dart`. 

```dart
Cores.azulPrimario   // #00488D — azul institucional
Cores.fundoPagina    // #F1F4FA — fundo geral das telas
Cores.branco         // #FFFFFF — fundo de cards e painéis
Cores.pretoProfundo  // #181C20 — títulos
Cores.cinzaEscuro    // #424752 — textos secundários
Cores.cinzaMedio     // #727783 — placeholders
Cores.cinzaClaro     // #DFE3E8 — bordas e divisores
```

### Tipografia

Definida em `lib/nucleo/temas/tipografia.dart`. Use sempre com `.copyWith()` para customizar.

| Estilo | Fonte | Tamanho | Uso |
|---|---|---|---|
| `Tipografia.headlineLarge` | Poppins SemiBold | 32px | Títulos principais |
| `Tipografia.headlineMedium` | Poppins Regular | 28px | Títulos de cards |
| `Tipografia.headlineSmall` | Poppins Regular | 24px | Logo e subtítulos |
| `Tipografia.titleMedium` | Poppins Medium | 16px | Texto de botões |
| `Tipografia.bodyLarge` | Roboto Regular | 16px | Textos corridos |
| `Tipografia.bodyMedium` | Roboto Regular | 14px | Textos de apoio |
| `Tipografia.labelMedium` | Roboto Bold | 12px | Labels de campos |

---

## Páginas implementadas

| Página | Rota / Widget | Status |
|---|---|---|
| Login | `PaginaLogin` |  UI completa |
| Cadastro | `PaginaCadastro` |  Integrado com API |
| Sucesso do Cadastro | `PaginaSucessoCadastro` |  UI completa |
| Recuperar Senha | `PaginaRecuperarSenha` |  UI completa |
| E-mail Enviado | `PaginaEmailEnviado` |  UI completa |
| Nova Senha | `PaginaNovaSenha` |  UI completa |

---

## Integração com a API

O frontend se comunica com a **gerelat-api** (Django REST Framework).

**URL base:** `http://localhost:8000`

| Endpoint | Método | Usado em |
|---|---|---|
| `/auth/register/` | POST | Página de cadastro |
| `/auth/login/` | POST | Página de login (TODO) |
| `/auth/password/reset/` | POST | Recuperar senha (TODO) |

Para rodar a API localmente, acesse o repositório `gerelat-api` e siga as instruções de setup com Docker.

---

## Dependências

```yaml
google_fonts: ^6.2.1   # Fontes Poppins e Roboto via CDN
http: ^1.2.2           # Requisições HTTP para a API
cupertino_icons: ^1.0.8
```

---
