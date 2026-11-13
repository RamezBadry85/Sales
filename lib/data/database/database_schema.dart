/// SQL schema definitions for the local SQLite database.
///
/// The schema is versioned and evolves through explicit migrations. Tables for
/// later phases (quotations, sales records) are created up front so that the
/// master data can be referenced by foreign keys from the beginning and no
/// destructive migration is required later.
class DatabaseSchema {
  const DatabaseSchema._();

  /// Current schema version. Increment together with a migration step.
  static const int version = 1;

  static const String customersTable = 'customers';
  static const String productsTable = 'products';
  static const String quotationsTable = 'quotations';
  static const String quotationItemsTable = 'quotation_items';
  static const String salesRecordsTable = 'sales_records';

  /// Statements executed when the database is created for the first time.
  static const List<String> createStatements = <String>[
    '''
    CREATE TABLE customers (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT NOT NULL COLLATE NOCASE,
      account_name TEXT,
      contact_person TEXT,
      phone TEXT,
      email TEXT,
      address TEXT,
      notes TEXT,
      created_at TEXT NOT NULL,
      updated_at TEXT NOT NULL
    )
    ''',
    '''
    CREATE TABLE products (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      category TEXT,
      company TEXT,
      code TEXT,
      description TEXT NOT NULL COLLATE NOCASE,
      unit TEXT,
      default_price TEXT,
      notes TEXT,
      created_at TEXT NOT NULL,
      updated_at TEXT NOT NULL
    )
    ''',
    '''
    CREATE TABLE quotations (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      quotation_number TEXT NOT NULL,
      quotation_date TEXT NOT NULL,
      customer_id INTEGER,
      account_name TEXT,
      account_address TEXT,
      payment_method TEXT,
      rsm_manager TEXT,
      area_manager TEXT,
      notes TEXT,
      total_before_discount TEXT,
      total_after_discount TEXT,
      total_discount TEXT,
      overall_discount_percentage TEXT,
      created_at TEXT NOT NULL,
      updated_at TEXT NOT NULL,
      FOREIGN KEY (customer_id) REFERENCES customers (id) ON DELETE RESTRICT
    )
    ''',
    '''
    CREATE TABLE quotation_items (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      quotation_id INTEGER NOT NULL,
      product_id INTEGER,
      category TEXT,
      company TEXT,
      code TEXT,
      description TEXT NOT NULL,
      unit TEXT,
      quantity TEXT NOT NULL DEFAULT '0',
      unit_price TEXT NOT NULL DEFAULT '0',
      discount_percentage TEXT NOT NULL DEFAULT '0',
      sort_order INTEGER NOT NULL DEFAULT 0,
      created_at TEXT NOT NULL,
      updated_at TEXT NOT NULL,
      FOREIGN KEY (quotation_id) REFERENCES quotations (id) ON DELETE CASCADE,
      FOREIGN KEY (product_id) REFERENCES products (id) ON DELETE SET NULL
    )
    ''',
    '''
    CREATE TABLE sales_records (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      customer_id INTEGER,
      representative TEXT,
      hospital TEXT,
      year INTEGER,
      month INTEGER,
      product_id INTEGER,
      category TEXT,
      company TEXT,
      code TEXT,
      description TEXT,
      quantity TEXT NOT NULL DEFAULT '0',
      unit_price TEXT NOT NULL DEFAULT '0',
      total_value TEXT NOT NULL DEFAULT '0',
      sales_date TEXT,
      notes TEXT,
      created_at TEXT NOT NULL,
      updated_at TEXT NOT NULL,
      FOREIGN KEY (customer_id) REFERENCES customers (id) ON DELETE RESTRICT,
      FOREIGN KEY (product_id) REFERENCES products (id) ON DELETE SET NULL
    )
    ''',
    'CREATE INDEX idx_customers_name ON customers (name)',
    'CREATE INDEX idx_customers_account_name ON customers (account_name)',
    'CREATE INDEX idx_products_code ON products (code)',
    'CREATE INDEX idx_products_description ON products (description)',
    'CREATE INDEX idx_products_company ON products (company)',
    'CREATE INDEX idx_products_category ON products (category)',
    'CREATE INDEX idx_quotations_customer ON quotations (customer_id)',
    'CREATE INDEX idx_quotations_date ON quotations (quotation_date)',
    'CREATE INDEX idx_quotation_items_quotation ON quotation_items (quotation_id)',
    'CREATE INDEX idx_sales_customer ON sales_records (customer_id)',
    'CREATE INDEX idx_sales_date ON sales_records (sales_date)',
    'CREATE INDEX idx_sales_product ON sales_records (product_id)',
  ];

  /// Migration steps keyed by the version they upgrade *to*.
  ///
  /// Each entry receives the database batch so upgrades stay transactional.
  /// Version 1 is the initial schema; future versions add their statements
  /// here and increment [version].
  static const Map<int, List<String>> migrations = <int, List<String>>{
    // 2: <String>['ALTER TABLE customers ADD COLUMN ...'],
  };
}
