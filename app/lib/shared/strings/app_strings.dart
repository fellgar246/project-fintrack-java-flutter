/// Centralized user-facing copy so screens never hardcode text — prepared
/// for future i18n. Only auth strings live here for now; grows per feature.
class AppStrings {
  AppStrings._();

  static const loginTitle = 'Iniciar sesión';
  static const registerTitle = 'Crear cuenta';
  static const emailLabel = 'Correo electrónico';
  static const passwordLabel = 'Contraseña';
  static const confirmPasswordLabel = 'Confirmar contraseña';
  static const nameLabel = 'Nombre';
  static const loginButton = 'Entrar';
  static const registerButton = 'Crear cuenta';
  static const logoutButton = 'Cerrar sesión';
  static const noAccountPrompt = '¿No tienes cuenta? Regístrate';
  static const hasAccountPrompt = '¿Ya tienes cuenta? Inicia sesión';

  static const invalidCredentials = 'Credenciales inválidas';
  static const emailAlreadyRegistered = 'Ese correo ya está registrado';

  static const emailRequired = 'Ingresa un correo';
  static const emailInvalid = 'Correo inválido';
  static const passwordRequired = 'Ingresa una contraseña';
  static const passwordTooShort = 'Mínimo 8 caracteres';
  static const passwordsDontMatch = 'Las contraseñas no coinciden';
  static const nameRequired = 'Ingresa tu nombre';

  // Settings
  static const settingsTitle = 'Ajustes';
  static const themeLabel = 'Tema';
  static const themeLight = 'Claro';
  static const themeDark = 'Oscuro';
  static const themeSystem = 'Sistema';
  static const logoutConfirmTitle = 'Cerrar sesión';
  static const logoutConfirmMessage = '¿Seguro que quieres cerrar sesión?';

  // Accounts
  static const accountsTitle = 'Cuentas';
  static const categoriesTitle = 'Categorías';
  static const accountsEmpty = 'Aún no tienes cuentas registradas';
  static const categoriesEmpty = 'Aún no tienes categorías en esta pestaña';
  static const createFirstAccount = 'Crea tu primera cuenta';
  static const createFirstCategory = 'Crea tu primera categoría';
  static const newAccountTitle = 'Nueva cuenta';
  static const editAccountTitle = 'Editar cuenta';
  static const accountNameLabel = 'Nombre';
  static const accountTypeLabel = 'Tipo';
  static const initialBalanceLabel = 'Saldo inicial';
  static const accountTypeCash = 'Efectivo';
  static const accountTypeDebit = 'Débito';
  static const accountTypeCredit = 'Crédito';
  static const accountTypeSavings = 'Ahorro';
  static const accountNameConflict = 'Ya existe una cuenta con ese nombre';
  static const deleteAccountTitle = 'Eliminar cuenta';
  static String deleteAccountMessage(String name) =>
      '¿Eliminar "$name"? Si tiene movimientos, se archivará y dejará de aparecer en la lista.';
  static const totalLabel = 'Total';
  static const showArchived = 'Mostrar archivadas';
  static const archivedLabel = 'Archivada';

  // Categories
  static const expenseTab = 'Gastos';
  static const incomeTab = 'Ingresos';
  static const newCategoryTitle = 'Nueva categoría';
  static const editCategoryTitle = 'Editar categoría';
  static const categoryNameLabel = 'Nombre';
  static const colorLabel = 'Color';
  static const hexColorLabel = 'Color hex';
  static const iconLabel = 'Icono';
  static const categoryNameConflict = 'Ya existe una categoría con ese nombre';
  static const deleteCategoryTitle = 'Eliminar categoría';
  static String deleteCategoryMessage(String name) =>
      '¿Eliminar "$name"? Si tiene movimientos o presupuestos, se archivará.';

  // Shared actions
  static const genericError = 'Ocurrió un error. Intenta de nuevo.';
  static const retryButton = 'Reintentar';
  static const saveButton = 'Guardar';
  static const createButton = 'Crear';
  static const cancelButton = 'Cancelar';
  static const deleteAction = 'Eliminar';
  static const amountRequired = 'Ingresa un monto';

  // Transactions
  static const transactionsTitle = 'Transacciones';
  static const newTransactionTitle = 'Nueva transacción';
  static const editTransactionTitle = 'Editar transacción';
  static const expenseType = 'Gasto';
  static const incomeType = 'Ingreso';
  static const transferType = 'Transferencia';
  static const categoryLabel = 'Categoría';
  static const accountLabel = 'Cuenta';
  static const transferAccountLabel = 'Cuenta destino';
  static const dateLabel = 'Fecha';
  static const todayLabel = 'Hoy';
  static const yesterdayLabel = 'Ayer';
  static const pickDateLabel = 'Elegir fecha';
  static const noteLabel = 'Nota';
  static const searchTransactions = 'Buscar movimientos';
  static const filterType = 'Tipo';
  static const filterAccount = 'Cuenta';
  static const filterCategory = 'Categoría';
  static const clearAllFilters = 'Limpiar todo';
  static const transactionsEmpty = 'Aún no registras movimientos';
  static const transactionsEmptyFiltered = 'No hay resultados para estos filtros';
  static const registerFirstTransaction = 'Registrar movimiento';
  static const noMoreTransactions = 'No hay más movimientos';
  static const deleteTransactionTitle = 'Eliminar transacción';
  static const deleteTransactionMessage =
      '¿Eliminar este movimiento? El saldo de la cuenta se actualizará.';
  static const sameAccountError = 'La cuenta origen y destino deben ser distintas';
  static const uncategorized = 'Sin categoría';

  // Budgets
  static const budgetsTitle = 'Presupuestos';
  static const budgetsEmpty = 'Aún no tienes presupuestos para este mes';
  static const createFirstBudget = 'Define tu primer presupuesto';
  static const newBudgetTitle = 'Nuevo presupuesto';
  static const editBudgetTitle = 'Editar presupuesto';
  static const budgetLimitLabel = 'Límite mensual';
  static const defineBudget = 'Definir';
  static const budgetSummaryTitle = 'Resumen del mes';
  static const budgetTotalLimit = 'Presupuestado';
  static const budgetTotalSpent = 'Gastado';
  static const budgetAvailable = 'Disponible';
  static const budgetUsedLabel = 'usado';
  static const budgetByCategory = 'Por categoría';
  static const unbudgetedSection = 'Sin presupuesto';
  static const copyFromPreviousMonth = 'Copiar del mes anterior';
  static const budgetsCopied = 'Presupuestos copiados del mes anterior';
  static const deleteBudgetTitle = 'Eliminar presupuesto';
  static const categoryRequired = 'Elige una categoría';
  static String budgetRemaining(String amount) => 'Te quedan $amount';
  static String budgetOver(String amount) => 'Te pasaste por $amount';
  static String deleteBudgetMessage(String name) =>
      '¿Eliminar el presupuesto de "$name"?';

  // Dashboard
  static const dashboardTitle = 'Dashboard';

  // Reports
  static const reportsTitle = 'Reportes';
  static const reportsByCategory = 'Por categoría';
  static const reportsTrend = 'Tendencia';
  static const reportsNoData = 'No hay movimientos en este periodo';
  static const exportCsvButton = 'Exportar CSV';
  static const exportCsvProgress = 'Exportando…';
  static const exportCsvTitle = 'Rango de exportación';
  static const exportCsvFrom = 'Desde';
  static const exportCsvTo = 'Hasta';
  static const exportCsvSubject = 'Exportación Fintrack';
  static String exportCsvSuccess(String path) => 'CSV guardado en $path';
}
