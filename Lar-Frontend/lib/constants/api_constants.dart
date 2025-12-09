class ApiConstants {
  static const baseUrl = 'http://10.0.2.2:8000/api';
  // static const baseUrl = 'http://127.0.0.1:8000/api';

  // Auth
  static const register = '/auth/register';
  static const login = '/auth/login';
  static const user = '/user';

  // Emergency Reports
  static const submitEmergency = '/reports/emergency';
  static const myEmergencyReports = '/reports/my';
  static const updateEmergency = '/admin/reports/emergency/update'; // append {id}

  // Aid Requests
  static const submitAid = '/reports/aid';
  static const myAidRequests = '/aid/my';
  static const updateAid = '/admin/reports/aid/update'; // append {id}

  // Bantuan Programs
  static const bantuanList = '/bantuan';
  static const createBantuan = '/admin/bantuan';
  static const updateBantuan = '/admin/bantuan'; // append {id}
  static const deleteBantuan = '/admin/bantuan'; // append {id}
}
