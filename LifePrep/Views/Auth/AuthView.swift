import SwiftUI

struct AuthView: View {
    @EnvironmentObject var authVM: AuthViewModel
    @State private var isLoginMode = true
    @State private var email = ""
    @State private var password = ""
    @State private var name = ""
    @State private var isPasswordVisible = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 32) {
                VStack(spacing: 8) {
                    Image(systemName: "shield.lefthalf.filled")
                        .font(.system(size: 64))
                        .foregroundStyle(.green)
                    Text("LifePrep")
                        .font(.largeTitle.bold())
                    Text("戰時生存準備指南")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.top, 40)

                VStack(spacing: 16) {
                    Picker("", selection: $isLoginMode) {
                        Text("登入").tag(true)
                        Text("註冊").tag(false)
                    }
                    .pickerStyle(.segmented)

                    if !isLoginMode {
                        TextField("顯示名稱", text: $name)
                            .textFieldStyle(.roundedBorder)
                            .autocorrectionDisabled()
                    }

                    TextField("電子郵件", text: $email)
                        .textFieldStyle(.roundedBorder)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                        .autocorrectionDisabled()

                    HStack {
                        Group {
                            if isPasswordVisible {
                                TextField("密碼（至少 6 位）", text: $password)
                                    .autocorrectionDisabled()
                                    .autocapitalization(.none)
                            } else {
                                SecureField("密碼（至少 6 位）", text: $password)
                            }
                        }
                        Button {
                            isPasswordVisible.toggle()
                        } label: {
                            Image(systemName: isPasswordVisible ? "eye.slash" : "eye")
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 8)
                    .background(Color(.systemBackground))
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color(.systemGray4)))
                    .clipShape(RoundedRectangle(cornerRadius: 8))

                    if let error = authVM.errorMessage {
                        Text(error)
                            .font(.caption)
                            .foregroundStyle(.red)
                            .multilineTextAlignment(.center)
                    }

                    Button(action: submit) {
                        Group {
                            if authVM.isLoading {
                                ProgressView()
                                    .tint(.white)
                            } else {
                                Text(isLoginMode ? "登入" : "建立帳號")
                                    .fontWeight(.semibold)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                        .background(Color.green)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .disabled(authVM.isLoading || !isFormValid)
                }
                .padding(.horizontal)

                Spacer()
            }
            .navigationTitle("")
            .navigationBarHidden(true)
        }
    }

    private var isFormValid: Bool {
        !email.isEmpty && !password.isEmpty && (isLoginMode || !name.isEmpty)
    }

    private func submit() {
        if isLoginMode {
            authVM.login(email: email, password: password)
        } else {
            authVM.register(email: email, password: password, name: name)
        }
    }
}
