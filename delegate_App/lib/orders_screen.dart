import 'package:delegate/settings_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({Key? key}) : super(key: key);

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final User? _currentUser = FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('إدارة الطلبات'),
        centerTitle: true,
        backgroundColor: Colors.red[800],
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: 'الإعدادات',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => UserSettingsScreen(
                    isLoggedIn: FirebaseAuth.instance.currentUser != null,
                  ),
                ),
              );
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(text: 'جديدة'),
            Tab(text: 'قيد التوصيل'),
            Tab(text: 'مكتملة'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildOrderList('جديدة'),
          _buildDeliveryOrderList(),
          _buildCompletedOrderList(),
        ],
      ),
    );
  }

  Widget _buildOrderList(String status) {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('orders')
          .where('status', isEqualTo: status)
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Center(child: Text('حدث خطأ في تحميل الطلبات'));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.data!.docs.isEmpty) {
          return Center(child: Text('لا توجد طلبات $status'));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(8),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            final doc = snapshot.data!.docs[index];
            final order = doc.data() as Map<String, dynamic>;

            return _buildOrderCard(doc, order, status);
          },
        );
      },
    );
  }

  Widget _buildDeliveryOrderList() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('orders')
          .where('status', isEqualTo: 'قيد التوصيل')
          .where('deliveryId', isEqualTo: _currentUser?.uid)
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Center(child: Text('حدث خطأ في تحميل الطلبات'));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.data!.docs.isEmpty) {
          return const Center(child: Text('لا توجد طلبات قيد التوصيل'));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(8),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            final doc = snapshot.data!.docs[index];
            final order = doc.data() as Map<String, dynamic>;

            return _buildOrderCard(doc, order, 'قيد التوصيل');
          },
        );
      },
    );
  }

  Widget _buildCompletedOrderList() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('orders')
          .where('status', isEqualTo: 'مكتملة')
          .where('deliveryId', isEqualTo: _currentUser?.uid)
          .orderBy('createdAt', descending: true)
          .limit(5)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Center(child: Text('حدث خطأ في تحميل الطلبات'));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.data!.docs.isEmpty) {
          return const Center(child: Text('لا توجد طلبات مكتملة'));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(8),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            final doc = snapshot.data!.docs[index];
            final order = doc.data() as Map<String, dynamic>;

            return _buildOrderCard(doc, order, 'مكتملة');
          },
        );
      },
    );
  }

  Widget _buildOrderCard(
    QueryDocumentSnapshot doc,
    Map<String, dynamic> order,
    String status,
  ) {
    double total = order['totalPrice'] ?? _calculateTotal(order['items']);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'طلب #${doc.id.substring(0, 6)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(
                  _formatDate(order['createdAt']),
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
            ),
            const Divider(),
            _buildCustomerInfo(order),
            if (order['items'] != null && order['items'].isNotEmpty) ...[
              const Text(
                'معلومات المتجر:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              _buildCustomerInfoRow(
                'اسم المتجر',
                order['items'][0]['storeName'],
              ),
              _buildCustomerInfoRow(
                'رقم المتجر',
                order['items'][0]['storeNumber'],
              ),
              if (order['items'][0]['latitude'] != null &&
                  order['items'][0]['longitude'] != null)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    'موقع المتجر: ${order['items'][0]['latitude'].toStringAsFixed(4)}, ${order['items'][0]['longitude'].toStringAsFixed(4)}',
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                ),
              const Divider(),
            ],
            if (order['deliveryId'] != null && status != 'جديدة')
              FutureBuilder(
                future: _firestore
                    .collection('users')
                    .doc(order['deliveryId'])
                    .get(),
                builder: (context, snapshot) {
                  if (snapshot.hasData) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        'المندوب: ${snapshot.data!['name'] ?? 'غير معروف'}',
                      ),
                    );
                  }
                  return const SizedBox();
                },
              ),
            const SizedBox(height: 8),
            Text(
              'المجموع: ${total.toStringAsFixed(2)}  ر.س',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ),
            const SizedBox(height: 8),
            ..._buildOrderItems(order['items']),
            const SizedBox(height: 12),
            if (status == 'جديدة')
              _buildActionButton(
                text: 'قبول الطلب',
                color: Colors.green,
                icon: Icons.check_circle,
                onPressed: () =>
                    _updateOrderStatus(doc.id, 'قيد التوصيل', context),
              ),
            if (status == 'قيد التوصيل')
              Column(
                children: [
                  _buildActionButton(
                    text: 'تم التوصيل',
                    color: Colors.blue,
                    icon: Icons.delivery_dining,
                    onPressed: () =>
                        _updateOrderStatus(doc.id, 'مكتملة', context),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 40),
                      side: const BorderSide(color: Colors.grey),
                    ),
                    onPressed: () => _showOrderDetails(order),
                    child: const Text('عرض التفاصيل الكاملة'),
                  ),
                ],
              ),
            if (status == 'مكتملة')
              Text(
                'الحالة: $status',
                style: TextStyle(
                  color: _getStatusColor(status),
                  fontWeight: FontWeight.bold,
                ),
              ),
          ],
        ),
      ),
    );
  }

  double _calculateTotal(List<dynamic> items) {
    return items.fold(0.0, (sum, item) {
      return sum + (item['price'] * item['quantity']);
    });
  }

  Widget _buildCustomerInfo(Map<String, dynamic> order) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (order['customerInfo'] != null) ...[
          _buildCustomerInfoRow('الاسم', order['customerInfo']['name']),
          _buildCustomerInfoRow('الهاتف', order['customerInfo']['phone']),
          _buildCustomerInfoRow(
            'العنوان',
            order['customerInfo']['address'],
            isMultiline: true,
          ),
          if (order['customerInfo']['coordinates'] != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                'الإحداثيات: ${order['customerInfo']['coordinates']['latitude'].toStringAsFixed(4)}, '
                '${order['customerInfo']['coordinates']['longitude'].toStringAsFixed(4)}',
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
              ),
            ),
          const Divider(),
        ] else ...[
          const Text('معلومات العميل غير متوفرة'),
          const Divider(),
        ],
      ],
    );
  }

  Widget _buildCustomerInfoRow(
    String title,
    String? value, {
    bool isMultiline = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$title: ', style: const TextStyle(fontWeight: FontWeight.bold)),
          Expanded(
            child: Text(
              value ?? 'غير معروف',
              style: const TextStyle(height: 1.4),
              softWrap: true,
              overflow: isMultiline
                  ? TextOverflow.visible
                  : TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required String text,
    required Color color,
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        icon: Icon(icon, color: Colors.white),
        label: Text(text, style: const TextStyle(color: Colors.white)),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          padding: const EdgeInsets.symmetric(vertical: 12),
        ),
        onPressed: onPressed,
      ),
    );
  }

  List<Widget> _buildOrderItems(List<dynamic> items) {
    return items.map<Widget>((item) {
      final product = item as Map<String, dynamic>;
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Container(
              width: 24,
              height: 24,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text('${product['quantity']}'),
            ),
            const SizedBox(width: 8),
            Expanded(child: Text(product['name'])),
            Text(
              '${(product['price'] * product['quantity']).toStringAsFixed(2)} ريال',
            ),
          ],
        ),
      );
    }).toList();
  }

  Future<void> _updateOrderStatus(
    String orderId,
    String newStatus,
    BuildContext context,
  ) async {
    try {
      await _firestore.collection('orders').doc(orderId).update({
        'status': newStatus,
        if (newStatus == 'قيد التوصيل') 'deliveryId': _auth.currentUser?.uid,
        if (newStatus == 'مكتملة') 'deliveredAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('تم تحديث حالة الطلب إلى $newStatus بنجاح'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('حدث خطأ: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showOrderDetails(Map<String, dynamic> order) {
    // حساب المجموع إذا كان غير موجود
    double total = order['totalPrice'] ?? _calculateTotal(order['items']);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Center(
                child: Text(
                  'تفاصيل الطلب',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 16),
              _buildDetailRow('تاريخ الطلب', _formatDate(order['createdAt'])),
              if (order.containsKey('deliveredAt'))
                _buildDetailRow(
                  'تاريخ التوصيل',
                  _formatDate(order['deliveredAt']),
                ),
              _buildDetailRow('الحالة', order['status']),
              const Divider(),

              const Text(
                'معلومات العميل:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              if (order['customerInfo'] != null) ...[
                _buildDetailRow('الاسم', order['customerInfo']['name']),
                _buildDetailRow('الهاتف', order['customerInfo']['phone']),
                _buildDetailRow('العنوان', order['customerInfo']['address']),
                if (order['customerInfo']['coordinates'] != null)
                  _buildDetailRow(
                    'الإحداثيات',
                    '${order['customerInfo']['coordinates']['latitude'].toStringAsFixed(4)}, '
                        '${order['customerInfo']['coordinates']['longitude'].toStringAsFixed(4)}',
                  ),
              ] else ...[
                const Text('معلومات العميل غير متوفرة'),
              ],
              const Divider(),

              const Text(
                'المنتجات:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              ...order['items'].map<Widget>((item) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Text('${item['quantity']} x '),
                      Expanded(child: Text(item['name'])),
                      Text('${item['price']} ريال'),
                    ],
                  ),
                );
              }),
              const Divider(),
              _buildDetailRow(
                'المجموع',
                '${total.toStringAsFixed(2)} ريال',
                isTotal: true,
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(String title, String? value, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$title: ',
            style: TextStyle(
              color: Colors.grey[600],
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Expanded(
            child: Text(
              value ?? 'غير معروف',
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
              style: TextStyle(
                fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
                color: isTotal ? Colors.red : Colors.black,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(Timestamp? timestamp) {
    if (timestamp == null) return 'غير معروف';
    return DateFormat('yyyy/MM/dd - hh:mm a').format(timestamp.toDate());
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'قيد التوصيل':
        return Colors.orange;
      case 'مكتملة':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }
}
