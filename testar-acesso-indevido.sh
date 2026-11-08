#!/usr/bin/env bash
# Testes de acesso indevido da API do Achei Barato.
# Rode no Git Bash (Windows) ou em qualquer terminal com curl:
#   bash testar-acesso-indevido.sh
# Os testes só tentam ler ou alterar dados de OUTRA conta, que a API deve recusar;
# os testes de controle só leem dados da própria conta. Nada é apagado.

BASE="${BASE:-http://200.19.1.19/20232GR.ADS0011/public/index.php}"
echo "API: $BASE"
read -p  "E-mail do consumidor 1: " U1_EMAIL;  read -s -p "Senha do consumidor 1: " U1_SENHA; echo
read -p  "E-mail do consumidor 2: " U2_EMAIL;  read -s -p "Senha do consumidor 2: " U2_SENHA; echo
read -p  "CNPJ do mercado 1: " M1_CNPJ;        read -s -p "Senha do mercado 1: " M1_SENHA; echo
read -p  "CNPJ do mercado 2: " M2_CNPJ;        read -s -p "Senha do mercado 2: " M2_SENHA; echo

login() { # tipo identificador senha
  curl -s -X POST "$BASE/login" -H 'Content-Type: application/json' \
    -d "{\"tipo\":\"$1\",\"identificador\":\"$2\",\"ds_senha\":\"$3\"}"
}
campo() { sed -n "s/.*\"$1\":\"\{0,1\}\([^\",}]*\).*/\1/p"; }

R=$(login usuario "$U1_EMAIL" "$U1_SENHA"); TU1=$(echo "$R" | campo token); U1=$(echo "$R" | campo id_usuario)
R=$(login usuario "$U2_EMAIL" "$U2_SENHA"); TU2=$(echo "$R" | campo token); U2=$(echo "$R" | campo id_usuario)
R=$(login mercado "$M1_CNPJ" "$M1_SENHA");  TM1=$(echo "$R" | campo token); M1=$(echo "$R" | campo id_mercado)
R=$(login mercado "$M2_CNPJ" "$M2_SENHA");  TM2=$(echo "$R" | campo token); M2=$(echo "$R" | campo id_mercado)

for v in TU1 TU2 TM1 TM2; do
  if [ -z "${!v}" ]; then
    echo "Falha no login ($v). Confira as credenciais e se a API nova (com AUTH_SECRET no .env) está publicada."; exit 1
  fi
done

OF1=$(curl -s "$BASE/produto_mercado?mercado=$M1" | campo id_produto_mercado | head -1)
if [ -z "$OF1" ]; then echo "O mercado 1 precisa ter pelo menos um produto cadastrado."; exit 1; fi
echo "Consumidores: $U1 e $U2 | Mercados: $M1 e $M2 | Oferta do mercado 1: $OF1"
echo

ok=0; total=0
teste() { # n descrição esperado token método rota [corpo]
  local n=$1 desc=$2 esp=$3 tok=$4 met=$5 rota=$6 corpo=${7:-}
  local args=(-s -o /tmp/ab_resp.json -w '%{http_code}' -X "$met" "$BASE/$rota" -H 'Content-Type: application/json')
  [ -n "$tok" ] && args+=(-H "Authorization: Bearer $tok")
  [ -n "$corpo" ] && args+=(-d "$corpo")
  local cod; cod=$(curl "${args[@]}")
  local msg; msg=$(campo mensagem < /tmp/ab_resp.json)
  local sit="FALHOU"; [ "$cod" = "$esp" ] && { sit="OK"; ok=$((ok+1)); }
  total=$((total+1))
  printf '%-3s %-6s esperado %s, obtido %s  %s  (%s)\n' "$n" "$sit" "$esp" "$cod" "$desc" "$msg"
}

OFERTA='{"nu_valor":0.01,"nu_qtde":0,"fl_promocao":false,"fl_disponivel":false}'
echo "== Sem login"
teste A1 "Consultar os dados do consumidor 1 sem token"           401 ""     GET    "usuarios/$U1"
teste A2 "Alterar a oferta do mercado 1 sem token"                401 ""     PUT    "produto_mercado/$OF1" "$OFERTA"
echo "== Consumidor 1 tentando acessar o consumidor 2"
teste B1 "Consultar os dados (CPF, e-mail) do consumidor 2"       403 "$TU1" GET    "usuarios/$U2"
teste B2 "Alterar o perfil do consumidor 2"                       403 "$TU1" PUT    "usuarios/$U2/perfil" '{"nm_usuario":"Invasor","ds_email":"x@x.com"}'
teste B3 "Listar todos os usuários"                               403 "$TU1" GET    "usuarios"
teste B4 "Consultar os favoritos do consumidor 2"                 403 "$TU1" GET    "favoritos?id_usuario=$U2"
teste B5 "Favoritar o mercado 1 em nome do consumidor 2"          403 "$TU1" POST   "mercado_favorito" "{\"id_usuario\":$U2,\"id_mercado\":$M1}"
teste B6 "Avaliar o mercado 1 em nome do consumidor 2"            403 "$TU1" POST   "mercados/$M1/avaliacao" "{\"id_usuario\":$U2,\"nu_nota\":1}"
teste B7 "Consultar as notificações do consumidor 2"              403 "$TU1" GET    "notificacoes?id_usuario=$U2"
echo "== Mercado 2 tentando acessar o mercado 1"
teste C1 "Alterar preço e estoque de uma oferta do mercado 1"     403 "$TM2" PUT    "produto_mercado/$OF1" "$OFERTA"
teste C2 "Excluir uma oferta do mercado 1"                        403 "$TM2" DELETE "produto_mercado/$OF1"
teste C3 "Alterar o perfil do mercado 1"                          403 "$TM2" PUT    "mercados/$M1/perfil" '{"nm_mercado":"Invasor"}'
teste C4 "Consultar o painel (resumo) do mercado 1"               403 "$TM2" GET    "mercados/$M1/resumo"
teste C5 "Consultar as notificações do mercado 1"                 403 "$TM2" GET    "notificacoes?id_mercado=$M1"
echo "== Perfil errado e token adulterado"
teste D1 "Consumidor 1 alterando uma oferta do mercado 1"         403 "$TU1" PUT    "produto_mercado/$OF1" "$OFERTA"
ULT=${TU1: -1}; [ "$ULT" = "A" ] && TROCA=B || TROCA=A
teste D2 "Token do consumidor 1 com a assinatura alterada"        401 "${TU1%?}$TROCA" GET "usuarios/$U1"
echo "== Controles (a própria conta e as consultas públicas continuam funcionando)"
teste E1 "Consumidor 1 consultando os próprios dados"             200 "$TU1" GET    "usuarios/$U1"
teste E2 "Mercado 1 consultando o próprio painel"                 200 "$TM1" GET    "mercados/$M1/resumo"
teste E3 "Comparação de preços sem login (pública)"               200 ""     GET    "produto_mercado/$OF1"
echo
echo "Resultado: $ok de $total testes com o código esperado."
echo "Tire uma captura de tela desta saída para usar como evidência no TCC."
