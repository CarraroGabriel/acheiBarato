# 🛒 Achei Barato

Aplicativo mobile comparador de preços de mercados regionais, desenvolvido como projeto de TCC. O **Achei Barato** reúne informações de preços e promoções de pequenos mercados e minimercados da região, ajudando o usuário a economizar nas compras do dia a dia sem precisar sair de casa para pesquisar.

---

## 💡 Sobre o Projeto

O app foi pensado especialmente para **jovens adultos** que estão começando a morar sozinhos e precisam controlar os gastos, e para **idosos** que buscam praticidade para encontrar produtos próximos sem grandes deslocamentos.

Com ele, o usuário consegue pesquisar produtos, comparar o preço de um mesmo produto entre os mercados, acompanhar promoções e descobrir onde comprar cada item para gastar menos.

---

## ✅ Funcionalidades

### Para o Usuário
- **Cadastro e login** de clientes
- **Busca de produtos** com filtros por categoria, marca, faixa de preço e promoção, e ordenação por relevância, menor preço, maior preço ou nome
- **Comparação de preços** — tela do produto com todos os mercados que o vendem, do menor para o maior preço, destacando o **melhor preço**, a promoção e a tele-entrega de cada um
- **Busca de mercados** com filtros por distância (raio), tele-entrega, avaliação mínima e mercados com promoções
- **Promoções em destaque** na tela principal, com as dos mercados favoritos primeiro
- **Mercado aberto ou fechado** nos cards da tela principal, de acordo com o horário de funcionamento
- **Tempo restante da promoção** — contagem regressiva ("Termina em 2h 35min") quando o mercado define um prazo
- **Favoritos** — mercados e produtos favoritos, com indicação de melhor preço entre os mercados
- **Detalhes do mercado** — endereço, tele-entrega e taxa de entrega, horário de funcionamento (com "aberto agora"), nota média e produtos disponíveis
- **Avaliação de mercados** — nota de 1 a 5 estrelas (uma por usuário, podendo ser alterada)
- **Perfil** — edição de nome e e-mail e exclusão da conta
- **Localização do usuário** pelo GPS do celular ou escolhida como no iFood: **busca pelo nome da rua** ou **pino no mapa** (arrastando o mapa até o local), útil para quem não quer compartilhar a localização ou quer ver mercados perto de outro endereço; a posição é compartilhada entre as telas enquanto o app está aberto
- **Mapa na tela principal** com a posição do usuário e os mercados como pontos, enquadrando os mais próximos; tocar em um mercado mostra a distância e abre seus detalhes
- **Distância até os mercados** e mercados mais próximos primeiro

### Para o Lojista
- **Cadastro do estabelecimento** com **endereço preenchido pelo CEP** (rua, bairro, cidade e UF via ViaCEP; o lojista completa o número)
- **Localização do mercado no mapa** — as coordenadas são obtidas pelo endereço ao salvar, ou pelo GPS com o botão "Usar minha localização atual", que também preenche o endereço (CEP, rua, número, bairro, cidade e UF) a partir da posição — útil quando o lojista está na loja
- **Painel do lojista** — visão geral com produtos cadastrados, em promoção, disponíveis, com estoque baixo e indisponíveis, nota média, quantidade de favoritos e avisos de informações faltando (horário e foto)
- **Gestão de produtos** — lista completa com filtros por situação (promoção, disponíveis, indisponíveis, estoque baixo) e por categoria
- **Cadastro de produtos** a partir do catálogo (categoria → produto → tipo → marca → embalagem), permitindo cadastrar produtos, tipos e marcas novos sem duplicar os existentes
- **Edição de produto** — preço, estoque, disponibilidade, promoção com percentual de desconto e prazo de término, e foto do produto
- **Perfil do mercado** — foto do estabelecimento, nome, e-mail, endereço completo (CEP, rua, número, bairro, cidade e UF), tele-entrega com taxa de entrega, horário de funcionamento por dia da semana e exclusão da conta

### Imagens
- **Fotos pela câmera ou galeria** do celular, reduzidas no app antes do envio e salvas no servidor (`public/uploads`); o banco guarda apenas o caminho do arquivo, com nome padronizado `{id}-{nome}.jpg` (ex.: `17-arroz-branco-5-kg-tio-joao.jpg`)
- **Imagem padrão dos produtos** incluída no app (`assets/produtos`, 512×512 px) e ligada pelo banco, usada quando o mercado não envia foto — ilustrações geradas com IA (Google Gemini)
- Ordem de exibição de um produto: foto enviada → imagem padrão → ícone

---

## 🔮 Adições Futuras (fora do escopo do TCC)

- 🛒 **Carrinho Inteligente / Pedidos** — sugere em qual mercado comprar cada item com base no menor preço. A aba **Pedidos** já aparece na navegação, mas apenas informa que a funcionalidade virá em uma versão futura.
- 📊 **Dashboard de vendas para os varejistas** — acompanhamento de vendas e desempenho dos produtos pelo lojista.
- 🪪 **API de validação de CPF/CNPJ** — verificação dos documentos informados no cadastro de clientes e mercados.

---

## 🖥️ Telas

| Tela | Descrição | Situação |
|---|---|---|
| Login / Cadastro | Acesso e cadastro de clientes e lojistas | ✅ Implementada |
| Tela Principal (Usuário) | Localização do usuário, mapa com os mercados, mercados mais próximos (com distância e aberto/fechado), promoções em destaque e menu lateral | ✅ Implementada |
| Buscar | Pesquisa de produtos e mercados com filtros e ordenação | ✅ Implementada |
| Produto / Comparação de Preços | Mercados que vendem o produto, melhor preço e favorito | ✅ Implementada |
| Detalhes do Mercado | Endereço, horário, tele-entrega, avaliação e produtos | ✅ Implementada |
| Favoritos | Mercados e produtos favoritos | ✅ Implementada |
| Perfil do Usuário | Edição de nome e e-mail e exclusão da conta | ✅ Implementada |
| Painel do Lojista | Visão geral, pendências e promoções atuais | ✅ Implementada |
| Produtos do Mercado (Lojista) | Lista de produtos com filtros | ✅ Implementada |
| Cadastro e Edição de Produtos (Lojista) | Cadastro pelo catálogo, preços, estoque, promoções e foto do produto | ✅ Implementada |
| Perfil do Mercado (Lojista) | Foto, dados do mercado, tele-entrega e horário de funcionamento | ✅ Implementada |
| Carrinho / Pedidos *(adição futura)* | Lista de itens com indicação do melhor mercado para cada um | 🔮 Futura |

---

## 🛠️ Tecnologias Utilizadas

| Camada | Tecnologia |
|---|---|
| Frontend / Mobile | [Flutter](https://flutter.dev) + Dart |
| Backend | PHP (API REST) |
| Banco de Dados | PostgreSQL |
| Localização | [geolocator](https://pub.dev/packages/geolocator) (posição do aparelho) e [Nominatim/OpenStreetMap](https://nominatim.org) (endereço → coordenadas, sem chave) |
| Mapa | [flutter_map](https://pub.dev/packages/flutter_map) + mapas do [OpenStreetMap](https://www.openstreetmap.org) (sem chave) |
| Endereço pelo CEP | [ViaCEP](https://viacep.com.br) (gratuita, sem chave) |
| Fotos (câmera/galeria) | [image_picker](https://pub.dev/packages/image_picker) |
| Notificações *(previsto)* | Firebase Cloud Messaging |

---

## 📌 Status do Projeto

🚧 **Em desenvolvimento** — Projeto de TCC (Trabalho de Conclusão de Curso)

Atualmente está prevista a implementação de:

- 🔔 **Notificações com Firebase** — aviso ao usuário quando um produto favoritado entrar em promoção (a relação de produtos favoritos já está pronta no banco)
