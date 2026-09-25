import SwiftUI

struct CatalogProduct:
    Identifiable,
    Codable
{
    let id: UUID
    var name: String
    var price: String
    var details: String

    init(
        id: UUID = UUID(),
        name: String,
        price: String,
        details: String
    ) {
        self.id = id
        self.name = name
        self.price = price
        self.details = details
    }
}

struct CatalogView: View {
    @State private var products:
        [CatalogProduct] = []

    @State private var showingAdd = false

    var body: some View {
        NavigationStack {
            Group {
                if products.isEmpty {
                    ContentUnavailableView(
                        "Your Catalog",
                        systemImage: "bag",
                        description: Text(
                            "Add products and services to share with customers."
                        )
                    )
                } else {
                    List(products) { product in
                        HStack(spacing: 14) {
                            RoundedRectangle(
                                cornerRadius: 12
                            )
                            .fill(
                                Color.secondary
                                    .opacity(0.12)
                            )
                            .frame(
                                width: 64,
                                height: 64
                            )
                            .overlay {
                                Image(
                                    systemName:
                                        "shippingbox.fill"
                                )
                                .foregroundStyle(
                                    .secondary
                                )
                            }

                            VStack(
                                alignment: .leading,
                                spacing: 4
                            ) {
                                Text(product.name)
                                    .font(.headline)

                                Text(product.price)
                                    .font(.subheadline)

                                Text(product.details)
                                    .font(.caption)
                                    .foregroundStyle(
                                        .secondary
                                    )
                                    .lineLimit(2)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Catalog")
            .toolbar {
                ToolbarItem(
                    placement:
                        .topBarTrailing
                ) {
                    Button {
                        showingAdd = true
                    } label: {
                        Image(
                            systemName: "plus"
                        )
                    }
                }
            }
            .sheet(
                isPresented: $showingAdd
            ) {
                AddCatalogProductView {
                    products.append($0)
                }
            }
        }
    }
}

private struct AddCatalogProductView: View {
    @Environment(\.dismiss)
    private var dismiss

    @State private var name = ""
    @State private var price = ""
    @State private var details = ""

    let onSave:
        (CatalogProduct) -> Void

    var body: some View {
        NavigationStack {
            Form {
                Section("Product") {
                    TextField(
                        "Name",
                        text: $name
                    )

                    TextField(
                        "Price",
                        text: $price
                    )
                    .keyboardType(
                        .decimalPad
                    )

                    TextField(
                        "Description",
                        text: $details,
                        axis: .vertical
                    )
                }
            }
            .navigationTitle(
                "New Product"
            )
            .toolbar {
                ToolbarItem(
                    placement:
                        .cancellationAction
                ) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(
                    placement:
                        .confirmationAction
                ) {
                    Button("Save") {
                        onSave(
                            CatalogProduct(
                                name: name,
                                price: price,
                                details: details
                            )
                        )

                        Haptics.success()
                        dismiss()
                    }
                    .disabled(
                        name
                            .trimmingCharacters(
                                in: .whitespaces
                            )
                            .isEmpty
                    )
                }
            }
        }
    }
}
