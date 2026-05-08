

import WidgetKit
import SwiftUI

// MARK: - Timeline Entry

struct SpendEntry: TimelineEntry {

    let date: Date
    let widgetData: WidgetData
}

// MARK: - Timeline Provider

struct SpendProvider: TimelineProvider {

    func placeholder(
        in context: Context
    ) -> SpendEntry {

        SpendEntry(
            date: Date(),

            widgetData: WidgetData(
                totalSpent: 4230,
                topCategory: "Food & Dining",
                topEmoji: "🍔",
                count: 12,
                lastUpdated: Date()
            )
        )
    }

    func getSnapshot(
        in context: Context,
        completion: @escaping (SpendEntry) -> Void
    ) {

        completion(
            SpendEntry(
                date: Date(),

                widgetData:
                    SharedDataManager.getWidgetData()
            )
        )
    }

    func getTimeline(
        in context: Context,
        completion: @escaping (
            Timeline<SpendEntry>
        ) -> Void
    ) {

        let entry = SpendEntry(
            date: Date(),

            widgetData:
                SharedDataManager.getWidgetData()
        )

        let nextUpdate =
        Calendar.current.date(
            byAdding: .hour,
            value: 2,
            to: Date()
        )!

        let timeline = Timeline(
            entries: [entry],
            policy: .after(nextUpdate)
        )

        completion(timeline)
    }
}

// MARK: - Small Widget

struct SmallSpendWidget: Widget {

    let kind = "SmallSpendWidget"

    var body: some WidgetConfiguration {

        StaticConfiguration(
            kind: kind,
            provider: SpendProvider()
        ) { entry in

            SmallWidgetView(entry: entry)
        }
        .configurationDisplayName(
            "Monthly Spend"
        )
        .description(
            "See your total spending this month"
        )
        .supportedFamilies([
            .systemSmall
        ])
    }
}

// MARK: - Small Widget View

struct SmallWidgetView: View {

    let entry: SpendEntry

    var body: some View {

        VStack(
            alignment: .leading,
            spacing: 6
        ) {

            HStack {

                Text("💰")
                    .font(.title2)

                Spacer()

                Text("This month")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Text(
                "₹\(Int(entry.widgetData.totalSpent))"
            )
            .font(.title)
            .fontWeight(.bold)
            .foregroundStyle(.primary)
            .minimumScaleFactor(0.6)
            .lineLimit(1)

            Text(
                "\(entry.widgetData.count) transactions"
            )
            .font(.caption)
            .foregroundStyle(.secondary)

            HStack(spacing: 4) {

                Text(entry.widgetData.topEmoji)
                    .font(.caption2)

                Text(
                    entry.widgetData.topCategory
                        .components(
                            separatedBy: " "
                        )
                        .first ?? ""
                )
                .font(.caption2)
                .fontWeight(.medium)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                Color.purple.opacity(0.12)
            )
            .foregroundStyle(.purple)
            .clipShape(Capsule())
        }
        .padding()

        .containerBackground(
            for: .widget
        ) {

            Color(.systemBackground)
        }
    }
}

// MARK: - Medium Widget

struct MediumSpendWidget: Widget {

    let kind = "MediumSpendWidget"

    var body: some WidgetConfiguration {

        StaticConfiguration(
            kind: kind,
            provider: SpendProvider()
        ) { entry in

            MediumWidgetView(entry: entry)
        }
        .configurationDisplayName(
            "Spend Overview"
        )
        .description(
            "Spending summary with top category"
        )
        .supportedFamilies([
            .systemMedium
        ])
    }
}

// MARK: - Medium Widget View

struct MediumWidgetView: View {

    let entry: SpendEntry

    var body: some View {

        HStack(spacing: 0) {

            // Left Side

            VStack(
                alignment: .leading,
                spacing: 8
            ) {

                Label(
                    "SpendSense",
                    systemImage:
                        "indianrupeesign.circle.fill"
                )
                .font(.caption)
                .foregroundStyle(.purple)

                Spacer()

                Text(
                    "₹\(Int(entry.widgetData.totalSpent))"
                )
                .font(
                    .system(
                        size: 28,
                        weight: .bold
                    )
                )
                .minimumScaleFactor(0.6)
                .lineLimit(1)

                Text("spent this month")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Text(
                    "\(entry.widgetData.count) transactions"
                )
                .font(.caption2)
                .foregroundStyle(.secondary)
            }
            .frame(
                maxWidth: .infinity,
                alignment: .leading
            )

            Divider()
                .padding(.vertical, 8)
                .padding(.horizontal, 12)

            // Right Side

            VStack(
                alignment: .leading,
                spacing: 8
            ) {

                Text("Top spend")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Spacer()

                Text(entry.widgetData.topEmoji)
                    .font(
                        .system(size: 32)
                    )

                Text(
                    entry.widgetData.topCategory
                )
                .font(.caption)
                .fontWeight(.medium)
                .lineLimit(2)
                .minimumScaleFactor(0.8)

                Text(
                    "Updated \(entry.widgetData.lastUpdated.formatted(.relative(presentation: .named)))"
                )
                .font(.caption2)
                .foregroundStyle(.secondary)
            }
            .frame(
                maxWidth: .infinity,
                alignment: .leading
            )
        }
        .padding()

        .containerBackground(
            for: .widget
        ) {

            Color(.systemBackground)
        }
    }
}

// MARK: - Small Preview

#Preview(
    as: .systemSmall
) {

    SmallSpendWidget()

} timeline: {

    SpendEntry(
        date: Date(),

        widgetData: WidgetData(
            totalSpent: 4230,
            topCategory: "Food & Dining",
            topEmoji: "🍔",
            count: 12,
            lastUpdated: Date()
        )
    )
}

// MARK: - Medium Preview

#Preview(
    as: .systemMedium
) {

    MediumSpendWidget()

} timeline: {

    SpendEntry(
        date: Date(),

        widgetData: WidgetData(
            totalSpent: 9230,
            topCategory: "Shopping",
            topEmoji: "🛍️",
            count: 26,
            lastUpdated: Date()
        )
    )
}
