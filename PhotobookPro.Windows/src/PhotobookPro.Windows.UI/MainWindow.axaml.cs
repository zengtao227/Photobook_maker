using Avalonia.Controls;
using Avalonia.Interactivity;
using Avalonia.Markup.Xaml;
using Avalonia.Platform.Storage;
using PhotobookPro.Core.Export;
using PhotobookPro.Core.Migration;
using PhotobookPro.Core.Models;
using PhotobookPro.Core.Portable;

namespace PhotobookPro.Windows.UI;

public sealed partial class MainWindow : Window
{
    private Button? _openBundleButton;
    private Button? _relinkAssetsButton;
    private Button? _exportPdfButton;
    private TextBlock? _statusText;
    private string? _currentBundlePath;
    private string? _currentImagesPath;
    private Manifest? _currentManifest;
    private MigrationReport? _lastMigrationReport;

    public MainWindow()
    {
        InitializeComponent();
        _openBundleButton = this.FindControl<Button>("OpenBundleButton");
        _relinkAssetsButton = this.FindControl<Button>("RelinkAssetsButton");
        _exportPdfButton = this.FindControl<Button>("ExportPdfButton");
        _statusText = this.FindControl<TextBlock>("StatusText");

        if (_openBundleButton is not null)
            _openBundleButton.Click += OpenBundleButtonOnClick;
        if (_relinkAssetsButton is not null)
            _relinkAssetsButton.Click += RelinkAssetsButtonOnClick;
        if (_exportPdfButton is not null)
            _exportPdfButton.Click += ExportPdfButtonOnClick;
    }

    private void InitializeComponent()
    {
        AvaloniaXamlLoader.Load(this);
    }

    private async void OpenBundleButtonOnClick(object? sender, RoutedEventArgs e)
    {
        var path = await PickFolderPathAsync("选择 .photobook 项目目录");
        if (string.IsNullOrWhiteSpace(path))
            return;

        try
        {
            var bundle = PhotobookBundleReader.Read(path);
            _currentBundlePath = path;
            _currentImagesPath = bundle.ImagesPath;
            _currentManifest = bundle.Manifest;

            _lastMigrationReport = MigrationWizard.AnalyzeMissingAssets(bundle.Manifest);
            if (_lastMigrationReport.MissingCount > 0)
                SetStatus($"已加载项目：{bundle.Manifest.ProjectName}，缺失资源：{_lastMigrationReport.MissingCount}。可以直接导出 PDF（缺失图片会留空），或点击“选择媒体根目录（可选）”进行重链接。媒体根目录通常是包含这些图片文件名的文件夹，或其下有 Images 子目录。");
            else
                SetStatus($"已加载项目：{bundle.Manifest.ProjectName}，Spreads：{bundle.Manifest.Spreads.Count}，Images：{bundle.ImagesPath}");
        }
        catch (Exception ex)
        {
            SetStatus($"加载失败：{ex.Message}");
        }
    }

    private async void RelinkAssetsButtonOnClick(object? sender, RoutedEventArgs e)
    {
        if (_currentManifest is null)
        {
            SetStatus("请先打开一个 .photobook 项目");
            return;
        }

        var mediaRoot = await PickFolderPathAsync("选择媒体根目录（包含照片文件）");
        if (string.IsNullOrWhiteSpace(mediaRoot))
        {
            SetStatus("已取消选择媒体根目录。你仍然可以直接导出 PDF。");
            return;
        }

        try
        {
            _currentManifest = MigrationWizard.RelinkMissingAssets(_currentManifest, mediaRoot);
            _lastMigrationReport = MigrationWizard.AnalyzeMissingAssets(_currentManifest);
            SetStatus($"重链接完成。剩余缺失资源：{_lastMigrationReport.MissingCount}。");
        }
        catch (Exception ex)
        {
            SetStatus($"重链接失败：{ex.Message}");
        }
    }

    private async void ExportPdfButtonOnClick(object? sender, RoutedEventArgs e)
    {
        if (_currentManifest is null)
        {
            SetStatus("请先打开一个 .photobook 项目");
            return;
        }

        var outputPath = await PickSavePdfPathAsync();
        if (string.IsNullOrWhiteSpace(outputPath))
            return;

        try
        {
            PdfExportService.ExportManifestToPdf(_currentManifest, outputPath);
            var suffix = _lastMigrationReport?.MissingCount > 0 ? $"（仍有缺失资源：{_lastMigrationReport.MissingCount}）" : "";
            SetStatus($"已导出：{outputPath}{suffix}");
        }
        catch (Exception ex)
        {
            SetStatus($"导出失败：{ex.Message}");
        }
    }

    private void SetStatus(string text)
    {
        if (_statusText is not null)
            _statusText.Text = text;
    }

    private async Task<string?> PickFolderPathAsync(string title)
    {
        var folders = await StorageProvider.OpenFolderPickerAsync(new FolderPickerOpenOptions
        {
            Title = title,
            AllowMultiple = false
        });

        return folders.FirstOrDefault()?.TryGetLocalPath();
    }

    private async Task<string?> PickSavePdfPathAsync()
    {
        var file = await StorageProvider.SaveFilePickerAsync(new FilePickerSaveOptions
        {
            Title = "导出 PDF",
            DefaultExtension = "pdf",
            SuggestedFileName = "PhotobookPro.pdf",
            FileTypeChoices =
            [
                new FilePickerFileType("PDF") { Patterns = ["*.pdf"] }
            ]
        });

        return file?.TryGetLocalPath();
    }
}
