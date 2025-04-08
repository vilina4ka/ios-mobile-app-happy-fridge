//
//  StatisticsViewController.swift
//  HappyFridge
//
//  Created by Вилина Ольховская on 29.04.2025.
//

import UIKit
import Combine
import DGCharts // Убедитесь, что импорт есть

final class StatisticsViewController: UIViewController {

    // MARK: - Properties
    private let viewModel = StatisticsViewModel()
    private var cancellables = Set<AnyCancellable>()

    // MARK: - UI Elements
    private lazy var scrollView: UIScrollView = { let s=UIScrollView();s.translatesAutoresizingMaskIntoConstraints=false;return s }()
    private lazy var contentView: UIView = { let v=UIView();v.translatesAutoresizingMaskIntoConstraints=false;return v }()

    private lazy var eatenOnTimeTitleLabel: UILabel = { let l=UILabel();l.translatesAutoresizingMaskIntoConstraints=false;l.text="Съедено в срок:";l.font = .systemFont(ofSize: 18);l.textColor = .secondaryLabel;return l }()
    private lazy var eatenOnTimePercentageLabel: UILabel = { let l=UILabel();l.translatesAutoresizingMaskIntoConstraints=false;l.font = .systemFont(ofSize: 60, weight: .bold);l.textColor=UIColor(red:138/255,green:185/255,blue:68/255,alpha:1.0);l.text="0%";return l }()
    private lazy var expiredTitleLabel: UILabel = { let l=UILabel();l.translatesAutoresizingMaskIntoConstraints=false;l.text="Наиболее часто у вас пропадали:";l.font = .systemFont(ofSize: 18);l.textColor = .secondaryLabel;return l }()

    private lazy var pieChartView: PieChartView = { // Тип изменен на PieChartView
        let chartView = PieChartView(); chartView.translatesAutoresizingMaskIntoConstraints = false
        chartView.drawEntryLabelsEnabled = true // Отображаем проценты на сегментах
        chartView.drawHoleEnabled = true; chartView.holeColor = .systemBackground
        chartView.holeRadiusPercent = 0.5; chartView.transparentCircleRadiusPercent = 0.53
        chartView.drawSlicesUnderHoleEnabled = false; chartView.usePercentValuesEnabled = true
        chartView.legend.enabled = false; chartView.chartDescription.enabled = false
        chartView.rotationEnabled = false; chartView.setExtraOffsets(left: 20, top: 0, right: 20, bottom: 0) // Увеличил боковые отступы для выносных линий
        chartView.entryLabelColor = .black // Цвет текста процентов
        chartView.entryLabelFont = .systemFont(ofSize: 14, weight: .medium) // Шрифт процентов
        return chartView
    }()

    private lazy var legendStackView: UIStackView = { let s=UIStackView();s.translatesAutoresizingMaskIntoConstraints=false;s.axis = .vertical;s.spacing=8;s.alignment = .leading;return s }()
    private lazy var noDataLabel: UILabel = { let l=UILabel();l.translatesAutoresizingMaskIntoConstraints=false;l.text="Пока нет данных о просроченных продуктах.";l.font = .systemFont(ofSize:16);l.textColor = .tertiaryLabel;l.textAlignment = .center;l.isHidden=true;return l }()

    // MARK: - Lifecycle Methods
    override func viewDidLoad() { super.viewDidLoad();view.backgroundColor = .systemBackground;title = "Статистика";setupUI();setupBindings();print("🟢 StatisticsVC: viewDidLoad.");viewModel.loadStatistics() }
    override func viewWillAppear(_ animated: Bool) { super.viewWillAppear(animated);self.tabBarController?.tabBar.isHidden=true }
    override func viewWillDisappear(_ animated: Bool) { super.viewWillDisappear(animated);if isMovingFromParent{self.tabBarController?.tabBar.isHidden=false} }

    // MARK: - UI Setup
    private func setupUI() {
        view.addSubview(scrollView); scrollView.addSubview(contentView)
        contentView.addSubview(eatenOnTimeTitleLabel); contentView.addSubview(eatenOnTimePercentageLabel)
        contentView.addSubview(expiredTitleLabel); contentView.addSubview(pieChartView)
        contentView.addSubview(legendStackView); contentView.addSubview(noDataLabel)
        let padding:CGFloat=20; let chartSize:CGFloat=250
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo:view.safeAreaLayoutGuide.topAnchor), scrollView.leadingAnchor.constraint(equalTo:view.leadingAnchor), scrollView.trailingAnchor.constraint(equalTo:view.trailingAnchor), scrollView.bottomAnchor.constraint(equalTo:view.bottomAnchor),
            contentView.topAnchor.constraint(equalTo:scrollView.contentLayoutGuide.topAnchor), contentView.leadingAnchor.constraint(equalTo:scrollView.contentLayoutGuide.leadingAnchor), contentView.trailingAnchor.constraint(equalTo:scrollView.contentLayoutGuide.trailingAnchor), contentView.bottomAnchor.constraint(equalTo:scrollView.contentLayoutGuide.bottomAnchor), contentView.widthAnchor.constraint(equalTo:scrollView.frameLayoutGuide.widthAnchor),
            eatenOnTimeTitleLabel.topAnchor.constraint(equalTo:contentView.topAnchor,constant:padding*1.5), eatenOnTimeTitleLabel.centerXAnchor.constraint(equalTo:contentView.centerXAnchor),
            eatenOnTimePercentageLabel.topAnchor.constraint(equalTo:eatenOnTimeTitleLabel.bottomAnchor,constant:8), eatenOnTimePercentageLabel.centerXAnchor.constraint(equalTo:contentView.centerXAnchor),
            expiredTitleLabel.topAnchor.constraint(equalTo:eatenOnTimePercentageLabel.bottomAnchor,constant:padding*2), expiredTitleLabel.centerXAnchor.constraint(equalTo:contentView.centerXAnchor),
            pieChartView.topAnchor.constraint(equalTo:expiredTitleLabel.bottomAnchor,constant:padding), pieChartView.centerXAnchor.constraint(equalTo:contentView.centerXAnchor), pieChartView.widthAnchor.constraint(equalToConstant:chartSize), pieChartView.heightAnchor.constraint(equalToConstant:chartSize),
            legendStackView.topAnchor.constraint(equalTo:pieChartView.bottomAnchor,constant:padding*1.5), legendStackView.leadingAnchor.constraint(equalTo:contentView.leadingAnchor,constant:padding*2), legendStackView.trailingAnchor.constraint(lessThanOrEqualTo:contentView.trailingAnchor,constant:-padding), legendStackView.bottomAnchor.constraint(equalTo:contentView.bottomAnchor,constant:-padding),
            noDataLabel.topAnchor.constraint(equalTo:expiredTitleLabel.bottomAnchor,constant:padding), noDataLabel.leadingAnchor.constraint(equalTo:contentView.leadingAnchor,constant:padding), noDataLabel.trailingAnchor.constraint(equalTo:contentView.trailingAnchor,constant:-padding), noDataLabel.bottomAnchor.constraint(equalTo:contentView.bottomAnchor,constant:-padding)
        ]); print("🟢 StatisticsVC: setupUI завершен.")
    }

    // MARK: - Bindings
    private func setupBindings() {
        viewModel.$usedInTimePercentageString.receive(on:DispatchQueue.main).assign(to:\.text!,on:eatenOnTimePercentageLabel).store(in:&cancellables)
        viewModel.$expiredChartData.receive(on:DispatchQueue.main).sink{[weak self] chartData in print("🔄 StatisticsVC: Обновление диаграммы/легенды. Сегментов: \(chartData.count)");self?.updatePieChart(with:chartData);self?.updateLegend(with:chartData)}.store(in:&cancellables)
        viewModel.$noExpiredData.receive(on:DispatchQueue.main).sink{[weak self] noData in print("🔄 StatisticsVC: Обновление видимости заглушки. noData = \(noData)");self?.pieChartView.isHidden=noData;self?.legendStackView.isHidden=noData;self?.noDataLabel.isHidden = !noData}.store(in:&cancellables)
        print("🟢 StatisticsVC: setupBindings завершен.")
    }

    // MARK: - UI Update Helpers
    /// Обновляет круговую диаграмму данными из ViewModel.
    private func updatePieChart(with data: [ChartDataEntry]) {
        print("➡️ StatisticsVC: Обновление Pie Chart View...")

        // --- ИЗМЕНЕНИЕ: Создаем записи с процентами, но БЕЗ label ---
        let entries = data.map { PieChartDataEntry(value: $0.percentage, label: nil) } // Label убираем отсюда
        // --- КОНЕЦ ИЗМЕНЕНИЯ ---

        let dataSet = PieChartDataSet(entries: entries, label: "")
        dataSet.colors = data.map { $0.color }
        dataSet.sliceSpace = 2
        dataSet.selectionShift = 5

        // Настройка значений (процентов) НА диаграмме
        dataSet.drawValuesEnabled = true // Включаем отображение значений
        dataSet.valueFont = .systemFont(ofSize: 14, weight: .medium) // Шрифт процентов
        dataSet.valueTextColor = .black // Цвет процентов
        // Форматтер для процентов
        let formatter = NumberFormatter()
        formatter.numberStyle = .percent // Стиль процента
        formatter.maximumFractionDigits = 0 // Целые проценты
        formatter.multiplier = 1.0 // Важно! Значения в dataSet УЖЕ являются процентами (0-100)
        dataSet.valueFormatter = DefaultValueFormatter(formatter: formatter)
        // Настройка выносных линий для значений
        dataSet.valueLinePart1OffsetPercentage = 0.8; dataSet.valueLinePart1Length = 0.4
        dataSet.valueLinePart2Length = 0.4; dataSet.valueLineColor = .systemGray4 // Цвет линии
        dataSet.yValuePosition = .outsideSlice // Значения снаружи сегментов

        let chartData = PieChartData(dataSet: dataSet)
        pieChartView.data = chartData
        pieChartView.notifyDataSetChanged()
        pieChartView.animate(xAxisDuration: 0.7, yAxisDuration: 0.7, easingOption: .easeOutQuad)
    }

    /// Обновляет легенду под диаграммой.
    private func updateLegend(with data: [ChartDataEntry]) {
        print("➡️ StatisticsVC: Обновление Legend Stack View...")
        legendStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        for entry in data {
            // --- ИЗМЕНЕНИЕ: Убираем проценты из текста легенды ---
            let legendItem = createLegendItem(color: entry.color, text: entry.category) // Только название категории
            // --- КОНЕЦ ИЗМЕНЕНИЯ ---
            legendStackView.addArrangedSubview(legendItem)
        }
    }

    /// Создает один элемент легенды (цветовой квадрат + текст).
    private func createLegendItem(color: UIColor, text: String) -> UIView {
        let container = UIStackView(); container.axis = .horizontal; container.spacing = 8; container.alignment = .center
        let colorView = UIView(); colorView.backgroundColor = color; colorView.translatesAutoresizingMaskIntoConstraints = false
        colorView.widthAnchor.constraint(equalToConstant: 16).isActive = true; colorView.heightAnchor.constraint(equalToConstant: 16).isActive = true; colorView.layer.cornerRadius = 4
        let label = UILabel(); label.text = text; label.font = .systemFont(ofSize: 15); label.textColor = .label
        container.addArrangedSubview(colorView); container.addArrangedSubview(label)
        return container
    }
}
