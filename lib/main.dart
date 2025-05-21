import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'dart:async';
import 'package:shimmer/shimmer.dart';
import 'package:animations/animations.dart';
import 'theme.dart';
import 'package:logging/logging.dart';
part 'main.g.dart';

// Models
@HiveType(typeId: 0)
class Product {
  @HiveField(0)
  final int id;
  @HiveField(1)
  final String name;
  @HiveField(2)
  int stock;
  @HiveField(3)
  final double price;

  Product({
    required this.id,
    required this.name,
    required this.stock,
    required this.price,
  });
}

@HiveType(typeId: 1)
enum OrderStatus {
  @HiveField(0)
  pending,
  @HiveField(1)
  processing,
  @HiveField(2)
  shipped,
  @HiveField(3)
  delivered,
  @HiveField(4)
  cancelled,
}

// Add this extension after the OrderStatus enum
extension OrderStatusColorExtension on OrderStatus {
  Color get toColor {
    switch (this) {
      case OrderStatus.pending:
        return Colors.orange;
      case OrderStatus.processing:
        return Colors.blue;
      case OrderStatus.shipped:
        return Colors.indigo;
      case OrderStatus.delivered:
        return Colors.green;
      case OrderStatus.cancelled:
        return Colors.red;
    }
  }
}

@HiveType(typeId: 2)
class Order {
  @HiveField(0)
  final int id;
  @HiveField(1)
  final int clientId;
  @HiveField(2)
  final DateTime date;
  @HiveField(3)
  final List<OrderItem> items;
  @HiveField(4)
  OrderStatus status;
  @HiveField(5)
  final int? employeeId;
  @HiveField(6)
  final String clientName;

  double get total =>
      items.fold(0, (sum, item) => sum + (item.price * item.quantity));

  Order({
    required this.id,
    required this.clientId,
    required this.date,
    required this.items,
    required this.clientName,
    this.status = OrderStatus.pending,
    this.employeeId,
  });
}

@HiveType(typeId: 3)
class OrderItem {
  @HiveField(0)
  final int productId;
  @HiveField(1)
  final String name;
  @HiveField(2)
  final int quantity;
  @HiveField(3)
  final double price;

  OrderItem({
    required this.productId,
    required this.name,
    required this.quantity,
    required this.price,
  });
}

@HiveType(typeId: 4)
class User {
  @HiveField(0)
  final String username;
  @HiveField(1)
  final String password;
  @HiveField(2)
  final String role;
  @HiveField(3)
  final String name;
  @HiveField(4)
  final int? clientId;
  @HiveField(5)
  final int? employeeId;
  @HiveField(6)
  final String status;

  const User({
    required this.username,
    required this.password,
    required this.role,
    required this.name,
    this.clientId,
    this.employeeId,
    this.status = 'pending', // Make status optional with default value
  });
}

@HiveType(typeId: 5)
class AttendanceLog {
  @HiveField(0)
  final String username;
  @HiveField(1)
  final String role;
  @HiveField(2)
  final DateTime timestamp;

  AttendanceLog({
    required this.username,
    required this.role,
    required this.timestamp,
  });
}

class CartItem {
  final Product product;
  int quantity;

  CartItem({
    required this.product,
    this.quantity = 1,
  });
}

// Controllers
/*
class AuthController extends GetxController {
  final isLoggedIn = false.obs;
  final isLoading = false.obs;
  final currentUser = Rx<User?>(null);
  final dataProvider = DataProvider();
  final _logger = Logger('AuthController');

  @override
  void onInit() {
    super.onInit();
    ever(isLoggedIn, _handleAuthChanged);
    // _loadSavedUser();
  }

  void _handleAuthChanged(bool loggedIn) {
    if (!loggedIn) {
      Get.offAllNamed('/login');
    }
  }

  // New method to initialize auth state
  Future<void> initializeAuth() async {
    try {
      final box = await Hive.openBox('auth');
      final savedUserData = box.get('userData');
      
      if (savedUserData != null) {
        final username = savedUserData['username'];
        final role = savedUserData['role'];
        
        final user = dataProvider.getUserByUsername(username);
        if (user != null && user.role == role) {
          currentUser.value = user;
          isLoggedIn.value = true;
          
          // Log attendance for Owner and Employee on auto-login
          if (user.role == 'Owner' || user.role == 'Employee') {
            await dataProvider.logAttendance(user);
          }
        }
      }
    } catch (e) {
      _logger.severe('Initialize auth error: $e');
    }
  }

  Future<void> _loadSavedUser() async {
    try {
      final box = await Hive.openBox('auth');
      final savedUserData = box.get('userData');
      
      if (savedUserData != null) {
        final username = savedUserData['username'];
        final role = savedUserData['role'];
        final rememberMe = savedUserData['rememberMe'] ?? false;
        
        // Remove this check to maintain login state regardless of rememberMe
        // if (!rememberMe) {
        //   await box.clear();
        //   return;
        // }
        
        final user = dataProvider.getUserByUsername(username);
        if (user != null && user.role == role) {
          currentUser.value = user;
          isLoggedIn.value = true;
          
          // Log attendance for Owner and Employee on auto-login
          if (user.role == 'Owner' || user.role == 'Employee') {
            await dataProvider.logAttendance(user);
          }
          
          Get.offAllNamed('/${role.toLowerCase()}');
        }
      }
    } catch (e) {
      _logger.severe('Load saved user error: $e');
    }
  }

  // Update login method to always save credentials
  Future<bool> login(String username, String password, String role, bool rememberMe) async {
    try {
      isLoading.value = true;
      final user = dataProvider.authenticateUser(username, password, role);
      
      if (user != null) {
        if (user.status != 'approved') {
          Get.snackbar(
            'Error',
            'Your account is pending approval or has been rejected',
            backgroundColor: Colors.red,
            colorText: Colors.white,
          );
          return false;
        }

        currentUser.value = user;
        isLoggedIn.value = true;

        // Always save user data
        final box = await Hive.openBox('auth');
        await box.put('userData', {
          'username': username,
          'role': role,
        });

        // Log attendance for Owner and Employee
        if (role == 'Owner' || role == 'Employee') {
          await dataProvider.logAttendance(user);
        }

        Get.offAllNamed('/${role.toLowerCase()}');
        return true;
      }

      Get.snackbar(
        'Error',
        'Invalid credentials',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return false;
    } catch (e) {
      _logger.severe('Login error: $e');
      Get.snackbar(
        'Error',
        'Login failed: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> logout() async {
    try {
      // Clear Hive auth box
      final box = await Hive.openBox('auth');
      await box.clear();

      // Clear user data from memory
      currentUser.value = null;
      isLoggedIn.value = false;

      // Clear cart and other data
      Get.find<OrderController>().cart.clear();
      Get.find<ProductController>().products.clear();

      // Navigate to login screen and remove all previous routes
      await Get.offAllNamed('/login');
    } catch (e) {
      _logger.severe('Logout error: $e');
      Get.snackbar(
        'Error',
        'Failed to logout: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }
}
*/
class AuthController extends GetxController {
  final isLoggedIn = false.obs;
  final isLoading = false.obs;
  final currentUser = Rx<User?>(null);
  final dataProvider = DataProvider();
  final _logger = Logger('AuthController');
  late Box authBox;

  @override
  void onInit() {
    super.onInit();
    ever(isLoggedIn, _handleAuthChanged);
    _initHiveBox();
  }

  Future<void> _initHiveBox() async {
    try {
      authBox = await Hive.openBox('auth');
      await initializeAuth();
    } catch (e) {
      _logger.severe('Failed to initialize Hive box: $e');
    }
  }

  void _handleAuthChanged(bool loggedIn) {
    if (!loggedIn && currentUser.value == null) {
      Get.offAllNamed('/login');
    }
  }

  /// Initializes authentication on app start based on Remember Me flag
  Future<void> initializeAuth() async {
    try {
      isLoading.value = true;

      if (!authBox.isOpen) {
        authBox = await Hive.openBox('auth');
      }

      final savedUserData = authBox.get('userData');

      if (savedUserData != null) {
        final username = savedUserData['username'];
        final password =
            savedUserData['password']; // Store encrypted in production
        final role = savedUserData['role'];
        final rememberMe = savedUserData['rememberMe'] ?? false;

        if (!rememberMe) {
          await authBox.clear();
          isLoading.value = false;
          return;
        }

        // Re-authenticate the user with stored credentials
        final user = dataProvider.authenticateUser(username, password, role);

        if (user != null && user.status == 'approved') {
          currentUser.value = user;
          isLoggedIn.value = true;

          if (user.role == 'Owner' ||
              user.role == 'Employee' ||
              user.role == 'Client') {
            await dataProvider.logAttendance(user);
          }

          // Navigate to appropriate screen based on role
          Get.offAllNamed('/${role.toLowerCase()}');
        } else {
          // Clear invalid stored credentials
          await authBox.clear();
        }
      }
    } catch (e) {
      _logger.severe('Initialize auth error: $e');
    } finally {
      isLoading.value = false;
    }
  }

  /// Login method with support for Remember Me
  Future<bool> login(
      String username, String password, String role, bool rememberMe) async {
    try {
      isLoading.value = true;
      final user = dataProvider.authenticateUser(username, password, role);

      if (user != null) {
        if (user.status != 'approved') {
          Get.snackbar(
            'Error',
            'Your account is pending approval or has been rejected',
            backgroundColor: Colors.red,
            colorText: Colors.white,
          );
          return false;
        }

        currentUser.value = user;
        isLoggedIn.value = true;

        // Ensure the box is open
        if (!authBox.isOpen) {
          authBox = await Hive.openBox('auth');
        }

        // Store credentials if Remember Me is checked
        if (rememberMe) {
          await authBox.put('userData', {
            'username': username,
            'password': password, // Encrypt this in production
            'role': role,
            'rememberMe': rememberMe,
          });
        } else {
          // Clear any previously saved data
          await authBox.clear();
        }

        if (role == 'Owner' || role == 'Employee') {
          await dataProvider.logAttendance(user);
        }

        Get.offAllNamed('/${role.toLowerCase()}');
        return true;
      }

      Get.snackbar(
        'Error',
        'Invalid credentials',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return false;
    } catch (e) {
      _logger.severe('Login error: $e');
      Get.snackbar(
        'Error',
        'Login failed: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  /// Logout method: clears user session and handles rememberMe logic
  Future<void> logout() async {
    try {
      if (!authBox.isOpen) {
        authBox = await Hive.openBox('auth');
      }

      final rememberMe = authBox.get('userData')?['rememberMe'] ?? false;

      // Only clear saved data if Remember Me is false
      if (!rememberMe) {
        await authBox.clear();
      }

      // Always clear current user state regardless of rememberMe
      currentUser.value = null;
      isLoggedIn.value = false;

      // Clear any other controller data
      try {
        Get.find<OrderController>().cart.clear();
      } catch (_) {
        // Controller might not be initialized
      }

      try {
        Get.find<ProductController>().products.clear();
      } catch (_) {
        // Controller might not be initialized
      }

      await Get.offAllNamed('/login');
    } catch (e) {
      _logger.severe('Logout error: $e');
      Get.snackbar(
        'Error',
        'Failed to logout: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }
}

// Data Provider
class DataProvider {
  static final DataProvider _instance = DataProvider._internal();
  factory DataProvider() => _instance;
  DataProvider._internal();

  // Add this field at the start of the class
  final _logger = Logger('DataProvider');

  // Sample data initialization
  final List<Product> _sampleProducts = [
    Product(id: 1, name: 'Product A', stock: 100, price: 29.99),
    Product(id: 2, name: 'Product B', stock: 50, price: 19.99),
    Product(id: 3, name: 'Product C', stock: 75, price: 39.99),
    Product(id: 4, name: 'Product D', stock: 60, price: 49.99),
    Product(id: 5, name: 'Product E', stock: 45, price: 59.99),
    Product(id: 6, name: 'Product F', stock: 80, price: 24.99),
    Product(id: 7, name: 'Product G', stock: 120, price: 34.99),
    Product(id: 8, name: 'Product H', stock: 90, price: 44.99),
    Product(id: 9, name: 'Product I', stock: 55, price: 54.99),
    Product(id: 10, name: 'Product J', stock: 40, price: 64.99),
  ];

  final List<User> _sampleUsers = [
    User(
        username: 'owner',
        password: 'password',
        role: 'Owner',
        name: 'Owner Admin',
        status: 'approved' // Set initial users as approved
        ),
    User(
        username: 'client1',
        password: 'password',
        role: 'Client',
        name: 'Alice Johnson',
        clientId: 1,
        status: 'approved'),
    User(
        username: 'client2',
        password: 'password',
        role: 'Client',
        name: 'Bob Smith',
        clientId: 2,
        status: 'approved'),
    User(
        username: 'client3',
        password: 'password',
        role: 'Client',
        name: 'Charlie Nguyen',
        clientId: 3,
        status: 'approved'),
    User(
        username: 'client4',
        password: 'password',
        role: 'Client',
        name: 'Dana White',
        clientId: 4,
        status: 'approved'),
    User(
        username: 'client5',
        password: 'password',
        role: 'Client',
        name: 'Eva Lopez',
        clientId: 5,
        status: 'approved'),
    User(
        username: 'employee1',
        password: 'password',
        role: 'Employee',
        name: 'John Doe',
        employeeId: 1,
        status: 'approved'),
    User(
        username: 'employee2',
        password: 'password',
        role: 'Employee',
        name: 'Jane Smith',
        employeeId: 2,
        status: 'approved'),
  ];

  // Hive box getters
  Box<Product> get productsBox => Hive.box<Product>('products');
  Box<Order> get ordersBox => Hive.box<Order>('orders');
  Box<User> get usersBox => Hive.box<User>('users');
  Box<AttendanceLog> get attendanceBox => Hive.box<AttendanceLog>('attendance');

  // Initialize data
  Future<void> initializeData() async {
    try {
      // Check if this is first run by checking if users box is empty
      final isFirstRun = usersBox.isEmpty;

      if (isFirstRun) {
        // Clear existing data only on first run
        await usersBox.clear();
        await productsBox.clear();

        // Add sample products
        for (var product in _sampleProducts) {
          await productsBox.put(product.id.toString(), product);
        }

        // Add sample users with approved status
        for (var user in _sampleUsers) {
          // Ensure all sample users are approved
          final approvedUser = User(
              username: user.username,
              password: user.password,
              role: user.role,
              name: user.name,
              clientId: user.clientId,
              employeeId: user.employeeId,
              status: 'approved' // Force approved status for sample users
              );
          await usersBox.put(user.username, approvedUser);
        }

        _logger.info('Sample data initialized successfully');
      }
    } catch (e) {
      _logger.severe('Error initializing data: $e');
    }
  }

  // Authentication methods
  User? authenticateUser(String username, String password, String role) {
    try {
      return usersBox.values.firstWhere(
        (user) =>
            user.username == username &&
            user.password == password &&
            user.role == role,
      );
    } catch (e) {
      return null;
    }
  }

  User? getUserByUsername(String username) => usersBox.get(username);

  // Product methods
  bool isProductNameExists(String name) {
    return productsBox.values
        .any((product) => product.name.toLowerCase() == name.toLowerCase());
  }

  Future<bool> addProduct(Product product) async {
    try {
      if (isProductNameExists(product.name)) {
        Get.snackbar(
          'Error',
          'Product already exists',
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        return false;
      }

      await productsBox.put(product.id.toString(), product);
      final controller = Get.find<ProductController>();
      controller.loadProducts();
      controller.update(); // Force UI update
      return true;
    } catch (e) {
      _logger.severe('Error adding product: $e');
      Get.snackbar(
        'Error',
        'Failed to add product',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return false;
    }
  }

  Future<void> deleteProduct(int productId) async {
    try {
      // Get all products and find the key for the product to delete
      final allProducts = productsBox.values.toList();
      final index = allProducts.indexWhere((p) => p.id == productId);

      if (index != -1) {
        // Delete using the box key
        final key = productsBox.keyAt(index);
        await productsBox.delete(key);

        // Force refresh products list
        Get.find<ProductController>().loadProducts();

        Get.snackbar(
          'Success',
          'Product deleted successfully',
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      _logger.severe('Error deleting product: $e');
      Get.snackbar(
        'Error',
        'Failed to delete product',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  List<Product> getAllProducts() {
    try {
      return productsBox.values.toList()..sort((a, b) => b.id.compareTo(a.id));
    } catch (e) {
      _logger.severe('Error getting products: $e');
      return [];
    }
  }

  Future<void> updateStock(int productId, int newStock) async {
    final product = productsBox.get(productId);
    if (product != null) {
      product.stock = newStock;
      await productsBox.put(productId, product);
    }
  }

  // Order methods
  List<Order> getOrdersByClientId(int clientId) {
    return ordersBox.values
        .where((order) => order.clientId == clientId)
        .toList();
  }

  List<Order> getOrdersByEmployeeId(int employeeId) {
    // Return all orders instead of filtering by employeeId
    return ordersBox.values.toList()
      ..sort((a, b) => b.date.compareTo(a.date)); // Sort by newest first
  }

  Future<void> createOrder(Order order) async {
    await ordersBox.add(order);
  }

  Future<void> updateOrderStatus(int orderId, OrderStatus newStatus) async {
    try {
      // Find the order with matching ID
      final orders = ordersBox.values.toList();
      final orderIndex = orders.indexWhere((order) => order.id == orderId);

      if (orderIndex != -1) {
        final order = orders[orderIndex];
        order.status = newStatus;

        // Update the order in the box using its key
        final key = ordersBox.keyAt(orderIndex);
        await ordersBox.put(key, order);

        Get.snackbar(
          'Success',
          'Order status updated successfully',
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to update order status: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  // Attendance methods
  Future<void> logAttendance(User user) async {
    final log = AttendanceLog(
      username: user.username,
      role: user.role,
      timestamp: DateTime.now(),
    );
    await attendanceBox.add(log);
  }

  List<AttendanceLog> getAttendanceLogs() {
    return attendanceBox.values.toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }

  Future<void> addClient(User client) async {
    await usersBox.put(client.username, client);
  }

  Future<void> deleteClient(String username) async {
    await usersBox.delete(username);
  }

  List<User> getClients() {
    return usersBox.values.where((user) => user.role == 'Client').toList();
  }

  List<Order> getClientOrders(int clientId) {
    return ordersBox.values
        .where((order) => order.clientId == clientId)
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }
}

// Product Controller

class ProductController extends GetxController {
  final dataProvider = DataProvider();
  final products = <Product>[].obs;

  // Add this field at the start of each class that needs logging
  final _logger = Logger('ProductController');

  @override
  void onInit() {
    super.onInit();
    loadProducts();
  }

  void loadProducts() {
    try {
      final allProducts = dataProvider.getAllProducts();
      products.clear(); // Clear existing products
      products.addAll(allProducts); // Add all products
      update(); // Force UI update
    } catch (e) {
      _logger.severe('Error loading products: $e');
    }
  }

  Future<void> addProduct(String name, int stock, double price) async {
    final product = Product(
      id: DateTime.now().millisecondsSinceEpoch,
      name: name,
      stock: stock,
      price: price,
    );

    await dataProvider.addProduct(product);
    loadProducts();
    Get.snackbar(
      'Success',
      'Product added successfully',
      backgroundColor: Colors.green,
      colorText: Colors.white,
    );
  }

  Future<void> deleteProduct(int productId) async {
    try {
      await dataProvider.deleteProduct(productId);
      // Force refresh the products list
      products.removeWhere((p) => p.id == productId);
      update();
    } catch (e) {
      _logger.severe('Error in controller deleting product: $e');
      Get.snackbar(
        'Error',
        'Failed to delete product',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }
}

// Order Controller
class OrderController extends GetxController {
  final dataProvider = DataProvider();
  final orders = <Order>[].obs;
  final cart = <CartItem>[].obs;

  double get cartTotal =>
      cart.fold(0, (sum, item) => sum + (item.quantity * item.product.price));

  void addToCart(Product product) {
    final existingItem = cart.firstWhereOrNull(
      (item) => item.product.id == product.id,
    );

    if (existingItem != null) {
      existingItem.quantity++;
      cart.refresh();
    } else {
      cart.add(CartItem(product: product));
    }
  }

  void removeFromCart(int index) {
    cart.removeAt(index);
  }

  void updateCartItemQuantity(int index, int quantity) {
    if (quantity > 0) {
      cart[index].quantity = quantity;
      cart.refresh();
    }
  }

  Future<void> placeOrder(int clientId, String clientName) async {
    if (cart.isEmpty) return;

    final order = Order(
      id: DateTime.now().millisecondsSinceEpoch,
      clientId: clientId,
      clientName: clientName,
      date: DateTime.now(),
      items: cart
          .map((item) => OrderItem(
                productId: item.product.id,
                name: item.product.name,
                quantity: item.quantity,
                price: item.product.price,
              ))
          .toList(),
    );

    await dataProvider.createOrder(order);
    cart.clear();
    loadOrders();
  }

  void loadOrders() {
    final user = Get.find<AuthController>().currentUser.value;
    if (user != null) {
      switch (user.role) {
        case 'Client':
          orders.value = dataProvider.getOrdersByClientId(user.clientId!);
          break;
        case 'Employee':
        case 'Owner':
          // Both employees and owners see all orders
          orders.value = dataProvider.ordersBox.values.toList()
            ..sort((a, b) => b.date.compareTo(a.date));
          break;
      }
    }
  }

  // Add method to update order status
  Future<void> updateOrderStatus(int orderId, OrderStatus newStatus) async {
    final user = Get.find<AuthController>().currentUser.value;
    if (user == null || (user.role != 'Owner' && user.role != 'Employee')) {
      Get.snackbar(
        'Error',
        'You do not have permission to update order status',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    await dataProvider.updateOrderStatus(orderId, newStatus);
    // Reload orders to refresh the UI
    loadOrders();
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Put DataProvider instance first
  final dataProvider = Get.put(DataProvider(), permanent: true);

  // Initialize Hive
  await initHive();

  // Initialize other controllers
  final authController = Get.put(AuthController(), permanent: true);
  Get.put(ProductController(), permanent: true);
  Get.put(OrderController(), permanent: true);

  // Try to restore login session
  await authController.initializeAuth();

  runApp(const InventoryApp());
}

Future<void> initHive() async {
  await Hive.initFlutter();

  // Register adapters
  if (!Hive.isAdapterRegistered(0)) Hive.registerAdapter(ProductAdapter());
  if (!Hive.isAdapterRegistered(1)) Hive.registerAdapter(OrderStatusAdapter());
  if (!Hive.isAdapterRegistered(2)) Hive.registerAdapter(OrderAdapter());
  if (!Hive.isAdapterRegistered(3)) Hive.registerAdapter(OrderItemAdapter());
  if (!Hive.isAdapterRegistered(4)) Hive.registerAdapter(UserAdapter());
  if (!Hive.isAdapterRegistered(5))
    Hive.registerAdapter(AttendanceLogAdapter());

  // Open boxes
  await Hive.openBox<Product>('products');
  await Hive.openBox<Order>('orders');
  await Hive.openBox<User>('users');
  await Hive.openBox<AttendanceLog>('attendance');
  await Hive.openBox('auth');

  // Initialize data using the already registered DataProvider instance
  await Get.find<DataProvider>().initializeData();
}

class InventoryApp extends StatelessWidget {
  const InventoryApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Inventory Management',
      theme: AppTheme.lightTheme,
      defaultTransition: Transition.cupertino,
      transitionDuration: const Duration(milliseconds: 500),
      initialBinding: BindingsBuilder(() {
        Get.put(DataProvider(), permanent: true);
        Get.put(AuthController(), permanent: true);
        Get.put(ProductController(), permanent: true);
        Get.put(OrderController(), permanent: true);
      }),
      initialRoute: '/login',
      getPages: [
        GetPage(
          name: '/login',
          page: () => const LoginScreen(),
          transition: Transition.fadeIn,
        ),
        GetPage(
          name: '/owner',
          page: () => const OwnerDashboard(),
          transition: Transition.zoom,
          middlewares: [AuthMiddleware()],
        ),
        GetPage(
          name: '/client',
          page: () => const ClientDashboard(),
          transition: Transition.zoom,
          middlewares: [AuthMiddleware()],
        ),
        GetPage(
          name: '/employee',
          page: () => const EmployeeDashboard(),
          transition: Transition.zoom,
          middlewares: [AuthMiddleware()],
        ),
      ],
    );
  }
}

// Add this middleware class
class AuthMiddleware extends GetMiddleware {
  @override
  RouteSettings? redirect(String? route) {
    final authController = Get.find<AuthController>();
    return authController.isLoggedIn.value
        ? null
        : const RouteSettings(name: '/login');
  }
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final usernameController = TextEditingController();
  final passwordController = TextEditingController();
  final selectedRole = RxString('Owner');
  final rememberMe = RxBool(false);
  final isLoading = RxBool(false);

  final AuthController controller = Get.find<AuthController>();

  @override
  void initState() {
    super.initState();
    // Check if there are stored credentials to pre-fill
    _checkStoredCredentials();
  }

  Future<void> _checkStoredCredentials() async {
    // This delays the check until after the widget is built
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        final box = await Hive.openBox('auth');
        final userData = box.get('userData');

        if (userData != null && userData['rememberMe'] == true) {
          // Pre-fill the fields with saved data
          usernameController.text = userData['username'] ?? '';
          // Don't pre-fill password for security, or implement securely
          // passwordController.text = userData['password'] ?? '';
          selectedRole.value = userData['role'] ?? 'Owner';
          rememberMe.value = true;
        }
      } catch (e) {
        debugPrint('Error checking stored credentials: $e');
      }
    });
  }

  @override
  void dispose() {
    usernameController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          child: Card(
            margin: const EdgeInsets.all(32),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 400),
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Inventory Management',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 24),
                  TextField(
                    controller: usernameController,
                    decoration: const InputDecoration(
                      labelText: 'Username',
                      prefixIcon: Icon(Icons.person),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: passwordController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Password',
                      prefixIcon: Icon(Icons.lock),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Obx(() => DropdownButtonFormField<String>(
                        value: selectedRole.value,
                        decoration: const InputDecoration(
                          labelText: 'Role',
                          prefixIcon: Icon(Icons.work),
                        ),
                        items: ['Owner', 'Client', 'Employee']
                            .map((role) => DropdownMenuItem(
                                  value: role,
                                  child: Text(role),
                                ))
                            .toList(),
                        onChanged: (value) => selectedRole.value = value!,
                      )),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: Obx(() => CheckboxListTile(
                              title: const Text('Remember Me'),
                              value: rememberMe.value,
                              onChanged: (value) =>
                                  rememberMe.value = value ?? false,
                              controlAffinity: ListTileControlAffinity.leading,
                              contentPadding: EdgeInsets.zero,
                            )),
                      ),
                      TextButton.icon(
                        onPressed: () => _showNewUserDialog(context),
                        icon: const Icon(Icons.person_add),
                        label: const Text('New User'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Obx(() => SizedBox(
                        width: double.infinity,
                        height: 40,
                        child: ElevatedButton(
                          onPressed:
                              controller.isLoading.value || isLoading.value
                                  ? null
                                  : () async {
                                      if (usernameController.text.isEmpty ||
                                          passwordController.text.isEmpty) {
                                        Get.snackbar(
                                          'Error',
                                          'Please enter username and password',
                                          backgroundColor: Colors.red,
                                          colorText: Colors.white,
                                        );
                                        return;
                                      }

                                      isLoading.value = true;
                                      try {
                                        final success = await controller.login(
                                          usernameController.text.trim(),
                                          passwordController.text,
                                          selectedRole.value,
                                          rememberMe.value,
                                        );
                                        if (!success) {
                                          isLoading.value = false;
                                        }
                                      } catch (_) {
                                        isLoading.value = false;
                                      }
                                    },
                          child: controller.isLoading.value || isLoading.value
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white),
                                  ),
                                )
                              : const Text('Login'),
                        ),
                      )),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showNewUserDialog(BuildContext context) {
    final nameController = TextEditingController();
    final passwordController = TextEditingController();
    final emailController = TextEditingController();
    final numberController = TextEditingController();
    final selectedRole = RxString('Client');
    final formKey = GlobalKey<FormState>();

    Get.dialog(
      AlertDialog(
        title: const Text('Create New User'),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Full Name',
                    prefixIcon: Icon(Icons.person),
                  ),
                  validator: (value) => (value == null || value.isEmpty)
                      ? 'Please enter your full name'
                      : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Password',
                    prefixIcon: Icon(Icons.lock),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a password';
                    }
                    if (value.length < 6) {
                      return 'Password must be at least 6 characters';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: emailController,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    prefixIcon: Icon(Icons.email),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) => (value == null || !value.contains('@'))
                      ? 'Please enter a valid email'
                      : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: numberController,
                  decoration: const InputDecoration(
                    labelText: 'Phone Number',
                    prefixIcon: Icon(Icons.phone),
                  ),
                  keyboardType: TextInputType.phone,
                  validator: (value) => (value == null || value.isEmpty)
                      ? 'Please enter your phone number'
                      : null,
                ),
                const SizedBox(height: 16),
                Obx(() => DropdownButtonFormField<String>(
                      value: selectedRole.value,
                      decoration: const InputDecoration(
                        labelText: 'Role',
                        prefixIcon: Icon(Icons.work),
                      ),
                      items: ['Client', 'Employee']
                          .map((role) => DropdownMenuItem(
                                value: role,
                                child: Text(role),
                              ))
                          .toList(),
                      onChanged: (value) => selectedRole.value = value!,
                    )),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                final newUser = User(
                  username: nameController.text,
                  password: passwordController.text,
                  role: selectedRole.value,
                  name: nameController.text,
                  clientId: selectedRole.value == 'Client'
                      ? DateTime.now().millisecondsSinceEpoch
                      : null,
                  employeeId: selectedRole.value == 'Employee'
                      ? DateTime.now().millisecondsSinceEpoch
                      : null,
                  status: 'pending',
                );

                await Get.find<DataProvider>().addClient(newUser);
                Get.back();
                Get.snackbar(
                  'Success',
                  'Registration submitted for approval',
                  backgroundColor: Colors.green,
                  colorText: Colors.white,
                );
              }
            },
            child: const Text('CREATE'),
          ),
        ],
      ),
    );
  }
}

class OwnerDashboard extends StatefulWidget {
  const OwnerDashboard({super.key});

  @override
  State<OwnerDashboard> createState() => _OwnerDashboardState();
}

class _OwnerDashboardState extends State<OwnerDashboard>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ProductController productController = Get.find();
  final OrderController orderController = Get.find();
  final dataProvider = Get.find<DataProvider>();

  // Add this field at the start of each class that needs logging
  final _logger = Logger('OwnerDashboard');

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this); // Changed to 5 tabs
    _tabController.addListener(() {
      setState(() {}); // Rebuild when tab changes
    });
    productController.loadProducts();
    orderController.loadOrders();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Owner Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => Get.find<AuthController>().logout(),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.inventory), text: 'Products'),
            Tab(icon: Icon(Icons.shopping_cart), text: 'Orders'),
            Tab(icon: Icon(Icons.people), text: 'Clients'),
            Tab(icon: Icon(Icons.person_pin_circle), text: 'Attendance'),
            Tab(icon: Icon(Icons.admin_panel_settings), text: 'User Requests'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildProductsTab(),
          _buildOrdersTab(),
          _buildClientsTab(),
          _buildAttendanceTab(),
          _buildUserRequestsTab(), // New tab
        ],
      ),
      floatingActionButton: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: _getFloatingActionButton(),
      ),
    );
  }

  Widget? _getFloatingActionButton() {
    // Only show FAB in Products tab (index 0)
    if (_tabController.index == 0) {
      return FloatingActionButton.extended(
        key: const ValueKey('add_product'),
        onPressed: _showAddProductDialog,
        icon: const Icon(Icons.add),
        label: const Text('Add Product'),
        backgroundColor: Colors.indigo,
      );
    }
    // Don't show FAB in other tabs
    return null;
  }

  Widget _buildProductsTab() {
    return Obx(() => AnimationLimiter(
          child: GridView.builder(
            padding: const EdgeInsets.all(8),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.90, // Increased height to prevent overflow
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
            ),
            itemCount: productController.products.length,
            itemBuilder: (context, index) {
              final product = productController.products[index];
              return AnimationConfiguration.staggeredGrid(
                position: index,
                columnCount: 2,
                duration: const Duration(milliseconds: 500),
                child: SlideAnimation(
                  verticalOffset: 50.0,
                  child: FadeInAnimation(
                    child: Card(
                      elevation: 12,
                      shadowColor: Colors.indigo.withAlpha(102),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Stack(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(24),
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  Colors.indigo[400]!,
                                  Colors.indigo[800]!,
                                ],
                              ),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Flexible(
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(12),
                                        color: Colors.white.withAlpha(38),
                                      ),
                                      child: Text(
                                        product.name,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                        textAlign: TextAlign.center,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    '\$${product.price.toStringAsFixed(2)}',
                                    style: const TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.w900,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 14,
                                    ),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(16),
                                      color: Colors.white.withAlpha(51),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.inventory_2_outlined,
                                          size: 26,
                                          color: Colors.white.withAlpha(230),
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          'Stock: ${product.stock}',
                                          style: TextStyle(
                                            fontSize: 20,
                                            color: Colors.white.withAlpha(230),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  SizedBox(width: double.infinity, height: 20
                                      // child: ElevatedButton.icon(
                                      //   onPressed: () => orderController.addToCart(product),
                                      //   icon: const Icon(Icons.add_shopping_cart, size: 16),
                                      //   label: const Text('Add to Cart'),
                                      //   style: ElevatedButton.styleFrom(
                                      //     foregroundColor: Colors.indigo,
                                      //     backgroundColor: Colors.white,
                                      //     padding: const EdgeInsets.symmetric(
                                      //       horizontal: 12,
                                      //       vertical: 8,
                                      //     ),
                                      //     textStyle: const TextStyle(
                                      //       fontSize: 14,
                                      //       fontWeight: FontWeight.bold,
                                      //     ),
                                      //   ),
                                      // ),

                                      )
                                ],
                              ),
                            ),
                          ),
                          // Add delete button
                          Positioned(
                            right: 8,
                            top: 8,
                            child: Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white.withAlpha(51),
                              ),
                              child: IconButton(
                                padding: EdgeInsets.zero,
                                icon: const Icon(
                                  Icons.delete_outline,
                                  size: 18,
                                  color: Colors.white,
                                ),
                                onPressed: () =>
                                    _showDeleteProductDialog(product),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ));
  }

  Widget _buildClientsTab() {
    return ListView.builder(
      itemCount: dataProvider.getClients().length,
      padding: const EdgeInsets.all(8),
      itemBuilder: (context, index) {
        final client = dataProvider.getClients()[index];
        return Card(
          child: ListTile(
            leading: const Icon(Icons.person),
            title: Text(client.name),
            subtitle: Text('Username: ${client.username}'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.shopping_bag),
                  onPressed: () => _showClientOrders(client),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _showDeleteClientDialog(client),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showAddClientDialog() {
    final nameController = TextEditingController();
    final usernameController = TextEditingController();
    final passwordController = TextEditingController();

    Get.dialog(
      AlertDialog(
        title: const Text('Add New Client'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Full Name'),
            ),
            TextField(
              controller: usernameController,
              decoration: const InputDecoration(labelText: 'Username'),
            ),
            TextField(
              controller: passwordController,
              decoration: const InputDecoration(labelText: 'Password'),
              obscureText: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () {
              final newClient = User(
                username: usernameController.text,
                password: passwordController.text,
                role: 'Client',
                name: nameController.text,
                clientId: DateTime.now().millisecondsSinceEpoch,
                status: 'approved', // Add status parameter
              );
              dataProvider.addClient(newClient);
              Get.back();
              setState(() {});
            },
            child: const Text('ADD'),
          ),
        ],
      ),
    );
  }

  void _showDeleteProductDialog(Product product) {
    Get.dialog(
      AlertDialog(
        title: const Text('Delete Product'),
        content: Text('Are you sure you want to delete ${product.name}?'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () {
              productController.deleteProduct(product.id);
              Get.back();
            },
            child: const Text('DELETE', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showDeleteClientDialog(User client) {
    Get.dialog(
      AlertDialog(
        title: const Text('Delete Client'),
        content: Text('Are you sure you want to delete ${client.name}?'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () {
              dataProvider.deleteClient(client.username);
              Get.back();
              setState(() {});
            },
            child: const Text('DELETE', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showClientOrders(User client) {
    final orders = dataProvider.getClientOrders(client.clientId!);

    Get.dialog(
      AlertDialog(
        title: Text('Orders - ${client.name}'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: orders.length,
            itemBuilder: (context, index) {
              final order = orders[index];
              return Card(
                child: ListTile(
                  title: Text('Order #${order.id}'),
                  subtitle: Text(_formatDate(order.date)),
                  trailing: Chip(
                    label: Text(
                      order.status.toString().split('.').last,
                      style: const TextStyle(color: Colors.white),
                    ),
                    backgroundColor: _getStatusColor(order.status),
                  ),
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('CLOSE'),
          ),
        ],
      ),
    );
  }

  Widget _buildOrdersTab() {
    return Obx(() => ListView.builder(
          itemCount: orderController.orders.length,
          padding: const EdgeInsets.all(8),
          itemBuilder: (context, index) {
            final order = orderController.orders[index];
            return Card(
              child: ExpansionTile(
                title: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Order #${order.id}'),
                          Text(
                            'Client: ${order.clientName}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                    PopupMenuButton<OrderStatus>(
                      tooltip: 'Update Status',
                      icon: const Icon(Icons.more_vert),
                      onSelected: (status) =>
                          orderController.updateOrderStatus(order.id, status),
                      itemBuilder: (context) => OrderStatus.values
                          .where((s) => s != order.status)
                          .map((status) => PopupMenuItem(
                                value: status,
                                child: Text(status.toString().split('.').last),
                              ))
                          .toList(),
                    ),
                    Chip(
                      label: Text(
                        order.status.toString().split('.').last,
                        style: const TextStyle(color: Colors.white),
                      ),
                      backgroundColor: _getStatusColor(order.status),
                    ),
                  ],
                ),
                subtitle: Text(_formatDate(order.date)),
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Order Items:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ...order.items.map((item) => ListTile(
                              title: Text(item.name),
                              subtitle: Text('Quantity: ${item.quantity}'),
                              trailing:
                                  Text('\$${item.price.toStringAsFixed(2)}'),
                            )),
                        const Divider(),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Total:',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            Text(
                              '\$${order.total.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: Colors.green,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ));
  }

  Widget _buildAttendanceTab() {
    final attendanceLogs = DataProvider().getAttendanceLogs();
    return ListView.builder(
      itemCount: attendanceLogs.length,
      padding: const EdgeInsets.all(8),
      itemBuilder: (context, index) {
        final log = attendanceLogs[index];
        return Card(
          child: ListTile(
            leading: Icon(
              log.role == 'Owner' ? Icons.admin_panel_settings : Icons.work,
              color: Theme.of(context).primaryColor,
            ),
            title: Text(log.username),
            subtitle: Text(_formatDate(log.timestamp)),
            trailing: IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () async {
                final box = await Hive.openBox<AttendanceLog>('attendance');
                await box.deleteAt(index);
                setState(() {});
              },
            ),
          ),
        );
      },
    );
  }

  void _showAddProductDialog() {
    final nameController = TextEditingController();
    final stockController = TextEditingController();
    final priceController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    Get.dialog(
      AlertDialog(
        title: const Text('Add New Product'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Product Name'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter product name';
                  }
                  if (dataProvider.isProductNameExists(value)) {
                    return 'A product with this name already exists';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: stockController,
                decoration: const InputDecoration(labelText: 'Initial Stock'),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter initial stock';
                  }
                  if (int.tryParse(value) == null) {
                    return 'Please enter a valid number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: priceController,
                decoration: const InputDecoration(labelText: 'Price'),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter price';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Please enter a valid price';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                final name = nameController.text;
                final stock = int.parse(stockController.text);
                final price = double.parse(priceController.text);

                final product = Product(
                  id: DateTime.now().millisecondsSinceEpoch,
                  name: name,
                  stock: stock,
                  price: price,
                );

                final success = await dataProvider.addProduct(product);
                if (success) {
                  Get.back();
                  Get.snackbar(
                    'Success',
                    'Product added successfully',
                    backgroundColor: Colors.green,
                    colorText: Colors.white,
                  );
                }
              }
            },
            child: const Text('ADD'),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(OrderStatus status) {
    return status.toColor;
  }

  String _formatDate(DateTime dateTime) {
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    final second = dateTime.second.toString().padLeft(2, '0');
    return '${dateTime.month}/${dateTime.day}/${dateTime.year} $hour:$minute:$second';
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Widget _buildUserRequestsTab() {
    return ValueListenableBuilder(
      valueListenable: dataProvider.usersBox.listenable(),
      builder: (context, Box<User> box, _) {
        final pendingUsers =
            box.values.where((user) => user.status == 'pending').toList();

        if (pendingUsers.isEmpty) {
          return const Center(
            child: Text('No pending user requests'),
          );
        }

        return ListView.builder(
          itemCount: pendingUsers.length,
          padding: const EdgeInsets.all(8),
          itemBuilder: (context, index) {
            final user = pendingUsers[index];
            return Card(
              elevation: 4,
              margin: const EdgeInsets.symmetric(vertical: 8),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'User Request',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const Divider(),
                    ListTile(
                      title: Text('Name: ${user.name}'),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Username: ${user.username}'),
                          Text('Role: ${user.role}'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => _handleUserRequest(user, false),
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.red,
                          ),
                          child: const Text('Reject'),
                        ),
                        const SizedBox(width: 16),
                        ElevatedButton(
                          onPressed: () => _handleUserRequest(user, true),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                          ),
                          child: const Text('Approve'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _handleUserRequest(User user, bool approved) async {
    final updatedUser = User(
      username: user.username,
      password: user.password,
      role: user.role,
      name: user.name,
      clientId: user.clientId,
      employeeId: user.employeeId,
      status: approved ? 'approved' : 'rejected',
    );

    if (approved) {
      await dataProvider.usersBox.put(user.username, updatedUser);
      Get.snackbar(
        'Success',
        'User request approved',
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } else {
      await dataProvider.usersBox.delete(user.username);
      Get.snackbar(
        'Success',
        'User request rejected',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }
}

class ClientDashboard extends StatefulWidget {
  const ClientDashboard({super.key});

  @override
  State<ClientDashboard> createState() => _ClientDashboardState();
}

class _ClientDashboardState extends State<ClientDashboard>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ProductController productController = Get.find();
  final OrderController orderController = Get.find();
  final AuthController authController = Get.find();
  final dataProvider = Get.find<DataProvider>();

  // Add this field at the start of each class that needs logging
  final _logger = Logger('ClientDashboard');
  Color _getStatusColor(OrderStatus status) {
    return status.toColor;
  }

  String _formatDate(DateTime dateTime) {
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    final second = dateTime.second.toString().padLeft(2, '0');
    return '${dateTime.month}/${dateTime.day}/${dateTime.year} $hour:$minute:$second';
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    productController.loadProducts();
    orderController.loadOrders();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
            'Welcome, ${authController.currentUser.value?.name ?? "Client"}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.shopping_cart),
            onPressed: _showCart,
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => authController.logout(),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.inventory), text: 'Products'),
            Tab(icon: Icon(Icons.history), text: 'Orders'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildProductsTab(),
          _buildOrdersTab(),
        ],
      ),
    );
  }

  Widget _buildProductsTab() {
    return Obx(() => AnimationLimiter(
          child: GridView.builder(
            padding: const EdgeInsets.all(8),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.70, // Increased height to prevent overflow
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
            ),
            itemCount: productController.products.length,
            itemBuilder: (context, index) {
              final product = productController.products[index];
              return AnimationConfiguration.staggeredGrid(
                  position: index,
                  columnCount: 2,
                  duration: const Duration(milliseconds: 500),
                  child: SlideAnimation(
                    verticalOffset: 50.0,
                    child: FadeInAnimation(
                      child: Card(
                        elevation: 12,
                        shadowColor: Colors.indigo.withAlpha(102),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(24),
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Colors.indigo[400]!,
                                Colors.indigo[800]!,
                              ],
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Flexible(
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 14,
                                    ),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(12),
                                      color: Colors.white.withAlpha(38),
                                    ),
                                    child: Text(
                                      product.name,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                      textAlign: TextAlign.center,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 48),
                                Text(
                                  '\$${product.price.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 20),
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton.icon(
                                    onPressed: () =>
                                        orderController.addToCart(product),
                                    icon: const Icon(Icons.add_shopping_cart,
                                        size: 16),
                                    label: const Text('Add to Cart'),
                                    style: ElevatedButton.styleFrom(
                                      foregroundColor: Colors.indigo,
                                      backgroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 8,
                                      ),
                                      textStyle: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ));
            },
          ),
        ));
  }

  Widget _buildOrdersTab() {
    return Obx(() => ListView.builder(
          itemCount: orderController.orders.length,
          padding: const EdgeInsets.all(8),
          itemBuilder: (context, index) {
            final order = orderController.orders[index];
            return Card(
              child: ExpansionTile(
                title: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Order #${order.id}'),
                          Text(
                            'Date: ${_formatDate(order.date)}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                    PopupMenuButton<OrderStatus>(
                      tooltip: 'Update Status',
                      icon: const Icon(Icons.more_vert),
                      onSelected: (status) =>
                          orderController.updateOrderStatus(order.id, status),
                      itemBuilder: (context) => OrderStatus.values
                          .where((s) => s != order.status)
                          .map((status) => PopupMenuItem(
                                value: status,
                                child: Text(status.toString().split('.').last),
                              ))
                          .toList(),
                    ),
                    Chip(
                      label: Text(
                        order.status.toString().split('.').last,
                        style: const TextStyle(color: Colors.white),
                      ),
                      backgroundColor: _getStatusColor(order.status),
                    ),
                  ],
                ),
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Order Items:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ...order.items.map((item) => ListTile(
                              title: Text(item.name),
                              subtitle: Text('Quantity: ${item.quantity}'),
                              trailing:
                                  Text('\$${item.price.toStringAsFixed(2)}'),
                            )),
                        const Divider(),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Total:',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            Text(
                              '\$${order.total.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: Colors.green,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ));
  }

  void _showCart() {
    Get.dialog(
      AlertDialog(
        title: const Text('Shopping Cart'),
        content: Obx(() {
          if (orderController.cart.isEmpty) {
            return const Text('Your cart is empty');
          }
          return SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: orderController.cart.length,
                    itemBuilder: (context, index) {
                      final item = orderController.cart[index];
                      return ListTile(
                        title: Text(item.product.name),
                        subtitle:
                            Text('\$${item.product.price.toStringAsFixed(2)}'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.remove),
                              onPressed: () {
                                if (item.quantity > 1) {
                                  orderController.updateCartItemQuantity(
                                      index, item.quantity - 1);
                                }
                              },
                            ),
                            Text('${item.quantity}'),
                            IconButton(
                              icon: const Icon(Icons.add),
                              onPressed: () {
                                orderController.updateCartItemQuantity(
                                    index, item.quantity + 1);
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete),
                              onPressed: () =>
                                  orderController.removeFromCart(index),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                const Divider(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Total:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      '\$${orderController.cartTotal.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        }),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('CLOSE'),
          ),
          ElevatedButton(
            onPressed: () {
              if (orderController.cart.isEmpty) return;
              final user = authController.currentUser.value;
              if (user != null) {
                orderController.placeOrder(
                  user.clientId!,
                  user.name,
                );
                Get.back();
                Get.snackbar(
                  'Success',
                  'Order placed successfully',
                  backgroundColor: Colors.green,
                  colorText: Colors.white,
                );
              }
            },
            child: const Text('PLACE ORDER'),
          ),
        ],
      ),
    );
  }
}

class EmployeeDashboard extends StatefulWidget {
  const EmployeeDashboard({super.key});

  @override
  State<EmployeeDashboard> createState() => _EmployeeDashboardState();
}

class _EmployeeDashboardState extends State<EmployeeDashboard> {
  final OrderController orderController = Get.find();
  final AuthController authController = Get.find();

  @override
  void initState() {
    super.initState();
    orderController.loadOrders();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
            'Welcome, ${authController.currentUser.value?.name ?? "Employee"}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => authController.logout(),
          ),
        ],
      ),
      body: _buildOrdersList(),
    );
  }

  Widget _buildOrdersList() {
    return Obx(() => ListView.builder(
          itemCount: orderController.orders.length,
          padding: const EdgeInsets.all(8),
          itemBuilder: (context, index) {
            final order = orderController.orders[index];
            return Card(
              child: ExpansionTile(
                title: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Order #${order.id}'),
                          Text(
                            'Date: ${_formatDate(order.date)}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                    PopupMenuButton<OrderStatus>(
                      tooltip: 'Update Status',
                      icon: const Icon(Icons.more_vert),
                      onSelected: (status) =>
                          orderController.updateOrderStatus(order.id, status),
                      itemBuilder: (context) => OrderStatus.values
                          .where((s) => s != order.status)
                          .map((status) => PopupMenuItem(
                                value: status,
                                child: Text(status.toString().split('.').last),
                              ))
                          .toList(),
                    ),
                    Chip(
                      label: Text(
                        order.status.toString().split('.').last,
                        style: const TextStyle(color: Colors.white),
                      ),
                      backgroundColor: _getStatusColor(order.status),
                    ),
                  ],
                ),
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Order Items:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ...order.items.map((item) => ListTile(
                              title: Text(item.name),
                              subtitle: Text('Quantity: ${item.quantity}'),
                              trailing:
                                  Text('\$${item.price.toStringAsFixed(2)}'),
                            )),
                        const Divider(),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Total:',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            Text(
                              '\$${order.total.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: Colors.green,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ));
  }

  Color _getStatusColor(OrderStatus status) {
    return status.toColor;
  }

  String _formatDate(DateTime dateTime) {
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    final second = dateTime.second.toString().padLeft(2, '0');
    return '${dateTime.month}/${dateTime.day}/${dateTime.year} $hour:$minute:$second';
  }
}
