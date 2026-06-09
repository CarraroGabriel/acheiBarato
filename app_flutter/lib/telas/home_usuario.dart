import 'package:flutter/material.dart';
import 'package:achei_barato/Widgets/app_bar.dart';

class HomeUsuario extends StatefulWidget {
  const HomeUsuario({super.key});

  @override
  State<HomeUsuario> createState() => _HomeUsuarioState();
}

class _HomeUsuarioState extends State<HomeUsuario> {
  int _abaSelecionada = 0;

  static const List<Map<String, dynamic>> _mercados = [
    {
      'nm_mercado':  'Supermercado Central',
      'distancia':   '0,3 km',
      'nu_avg_nota': '4.7',
      'fl_motoboy':  true,
    },
    {
      'nm_mercado':  'Mercado do Bairro',
      'distancia':   '0,7 km',
      'nu_avg_nota': '4.2',
      'fl_motoboy':  false,
    },
    {
      'nm_mercado':  'Atacadão Norte',
      'distancia':   '1,2 km',
      'nu_avg_nota': '4.5',
      'fl_motoboy':  true,
    },
    {
      'nm_mercado':  'Mineirão Mercados',
      'distancia':   '1,8 km',
      'nu_avg_nota': '3.9',
      'fl_motoboy':  false,
    },
  ];

  static const List<Map<String, dynamic>> _produtosDestaque = [
    {
      'nm_produto': 'Arroz Integral 5kg',
      'nm_mercado': 'Supermercado Central',
      'nu_valor':   'R\$ 18,90',
    },
    {
      'nm_produto': 'Leite Integral 1L',
      'nm_mercado': 'Mercado do Bairro',
      'nu_valor':   'R\$ 4,49',
    },
    {
      'nm_produto': 'Óleo de Soja 900ml',
      'nm_mercado': 'Atacadão Norte',
      'nu_valor':   'R\$ 6,79',
    },
    {
      'nm_produto': 'Café Torrado 500g',
      'nm_mercado': 'Mineirão Mercados',
      'nu_valor':   'R\$ 12,90',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AcheiBaratoAppBar(
        exibirBotaoVoltar: false,
        exibirMenu: true,
        acoes: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined,
                color: Colors.white),
            onPressed: () {},
          ),
        ],
      ),

      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(color: Colors.red),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: Colors.white,
                    child: Icon(Icons.person, color: Colors.red, size: 30),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Olá, Gabriel!',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.settings_outlined),
              title: const Text('Configurações'),
              onTap: () {},
            ),
            ListTile(
              leading: const Icon(Icons.help_outline),
              title: const Text('Ajuda'),
              onTap: () {},
            ),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text('Sair',
                  style: TextStyle(color: Colors.red)),
              onTap: () {},
            ),
          ],
        ),
      ),

      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [

            // LOCALIZAÇÃO DO CLIENTE
            Container(
              color: Colors.red.shade50,
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 10),
              child: Row(
                children: [
                  const Icon(Icons.location_on,
                      color: Colors.red, size: 20),
                  const SizedBox(width: 6),
                  const Expanded(
                    child: Text(
                      'Rua X, 123 — Gravataí, RS',
                      style: TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w500),
                    ),
                  ),
                  TextButton(
                    onPressed: () {},
                    style: TextButton.styleFrom(
                        foregroundColor: Colors.red,
                        padding: EdgeInsets.zero),
                    child: const Text('Alterar',
                        style: TextStyle(fontSize: 12)),
                  ),
                ],
              ),
            ),

            // MAPA
            Container(
              height: 260,
              color: Colors.grey.shade300,
              child: Stack(
                children: [
                  Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.map,
                            size: 48, color: Colors.grey.shade500),
                        Text(
                          'Mapa dos mercados próximos',
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  ),
                  const Center(
                    child: Icon(Icons.my_location,
                        color: Colors.red, size: 34),
                  ),
                  const Positioned(
                    top: 60, left: 70,
                    child: Icon(Icons.store, color: Colors.red, size: 28),
                  ),
                  const Positioned(
                    top: 100, right: 60,
                    child: Icon(Icons.store, color: Colors.red, size: 28),
                  ),
                  const Positioned(
                    bottom: 60, left: 130,
                    child: Icon(Icons.store, color: Colors.red, size: 28),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // MERCADOS PRÓXIMOS
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Mercados Próximos',
                    style: TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 140,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _mercados.length,
                      separatorBuilder: (_, __) =>
                      const SizedBox(width: 12),
                      itemBuilder: (_, i) =>
                          _buildCardMercado(_mercados[i]),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // PROMOÇÕES EM DESTAQUE
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: const [
                      Icon(Icons.local_offer,
                          color: Colors.red, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Promoções em Destaque',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                    const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 10,
                      crossAxisSpacing: 10,
                      childAspectRatio: 0.82,
                    ),
                    itemCount: _produtosDestaque.length,
                    itemBuilder: (_, i) =>
                        _buildCardProduto(_produtosDestaque[i]),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),

      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _abaSelecionada,
        selectedItemColor: Colors.red,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        onTap: (i) => setState(() => _abaSelecionada = i),
        items: const [
          BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home),
              label: 'Início'),
          BottomNavigationBarItem(
              icon: Icon(Icons.search),
              label: 'Buscar'),
          BottomNavigationBarItem(
              icon: Icon(Icons.favorite_outline),
              activeIcon: Icon(Icons.favorite),
              label: 'Favoritos'),
          BottomNavigationBarItem(
              icon: Icon(Icons.local_offer_outlined),
              activeIcon: Icon(Icons.local_offer),
              label: 'Promoções'),
          BottomNavigationBarItem(
              icon: Icon(Icons.shopping_cart_outlined),
              activeIcon: Icon(Icons.shopping_cart),
              label: 'Pedidos'),
        ],
      ),
    );
  }

  Widget _buildCardMercado(Map<String, dynamic> m) {
    return GestureDetector(
      onTap: () {
        // navegar para perfil_mercado
      },
      child: Container(
        width: 160,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: Colors.grey.shade200,
                  child: const Icon(Icons.store,
                      color: Colors.grey, size: 22),
                ),
                const Spacer(),
                if (m['fl_motoboy'])
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.delivery_dining,
                        color: Colors.green.shade600, size: 16),
                  ),
              ],
            ),
            const Spacer(),
            Text(
              m['nm_mercado'],
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                  fontSize: 13, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.star, color: Colors.amber, size: 13),
                const SizedBox(width: 3),
                Text(m['nu_avg_nota'],
                    style: const TextStyle(fontSize: 11)),
                const SizedBox(width: 8),
                Icon(Icons.location_on,
                    color: Colors.grey.shade400, size: 13),
                const SizedBox(width: 2),
                Text(m['distancia'],
                    style: TextStyle(
                        fontSize: 11, color: Colors.grey.shade500)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCardProduto(Map<String, dynamic> produto) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Stack(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Center(
                    child: Icon(Icons.image,
                        color: Colors.grey, size: 36),
                  ),
                ),
                Positioned(
                  top: 6,
                  left: 6,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'PROMO',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Text(
            produto['nm_produto'],
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
                fontSize: 12, fontWeight: FontWeight.bold),
          ),
          Text(
            produto['nm_mercado'],
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
                fontSize: 11, color: Colors.grey.shade500),
          ),
          const SizedBox(height: 4),
          Text(
            produto['nu_valor'],
            style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: Colors.red),
          ),
        ],
      ),
    );
  }
}