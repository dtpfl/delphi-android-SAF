unit Unit1;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes,
  System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs, FMX.Memo.Types,
  FMX.ScrollBox, FMX.Memo, FMX.Controls.Presentation, FMX.StdCtrls,
  System.Messaging,
  Androidapi.Helpers, Androidapi.JNI.Net,
  Androidapi.JNI.GraphicsContentViewText,
  Androidapi.JNI.Os, Androidapi.JNI.App, FMX.Objects, System.IOUtils,
  Androidapi.JNI.Widget,
  Androidapi.JNI.JavaTypes, FMX.TabControl, Androidapi.JNI.Provider,
  FMX.Platform.Android,
  Androidapi.JNIBridge, FMX.Surfaces, FMX.Helpers.Android, Androidapi.JNI.Media,
  Androidapi.JNI.Webkit, Androidapi.Jni, Posix.Unistd, Androidapi.JNI.Support;

type
  TForm1 = class(TForm)
    ButtonCreateANewFile: TButton;
    btnOpenFile: TButton;
    btnAccessToDir: TButton;
    BtnDeleteDoc: TButton;
    TabControl1: TTabControl;
    tiUriAl: TTabItem;
    tiSAF1: TTabItem;
    BtnInputStreamFromVirtFile: TButton;
    BtnOpenVirtFile: TButton;
    BtnEditDoc: TButton;
    btnOpenDocInputStream: TButton;
    tiIlave1: TTabItem;
    BtnReadTextFile: TButton;
    BtnShowPDF: TButton;
    btnSelectPDF: TButton;
    BtnPermanentPermission: TButton;
    ImageControl1: TImageControl;
    btnShowImage: TButton;
    tiIlave2: TTabItem;
    btnCopyInternalExternal: TButton;
    BtnCopyExternalInternal: TButton;
    BtnShareFile: TButton;
    BtnReviewDocMeta: TButton;
    BtnOpenDocBitmap: TButton;
    tiSAF2: TTabItem;
    Panel1: TPanel;
    Memo1: TMemo;
    MemoUri: TMemo;
    btnGetFileUri: TButton;
    btnFileRuler: TButton;
    procedure ButtonAllowAccessToOneDirectoryClick(Sender: TObject);
    procedure ButtonCreateANewFileClick(Sender: TObject);
    procedure ButtonOpenAFileClick(Sender: TObject);
    procedure ButtonDocumentDeleteClick(Sender: TObject);
    procedure ButtonPermanentPermissionsClick(Sender: TObject);
    procedure ButtonReadTextFileClick(Sender: TObject);
    procedure xButtonSelectPdfClick(Sender: TObject);
    procedure ButtonShowPdfClick(Sender: TObject);
    procedure MemoUriTap(Sender: TObject; const Point: TPointF);
    procedure ButtonOpenDocumentBitProcessClick(Sender: TObject);
    procedure ButtonShowImageClick(Sender: TObject);
    procedure ButtonInspectDocumentMetaDataClick(Sender: TObject);
    procedure TabControl1Change(Sender: TObject);
    procedure ButtonOpenDocumentInputStreamClick(Sender: TObject);
    procedure ButtonEditDocumentClick(Sender: TObject);
    procedure ButtonCopyFileFromInternalToExternalClick(Sender: TObject);
    procedure ButtonCopyFileFromExternalToInternalClick(Sender: TObject);
    procedure ButtonShareFileClick(Sender: TObject);
    procedure ButtonOpenAVirtualFileClick(Sender: TObject);
    procedure ButtonGetAnyFileUriClick(Sender: TObject);
    procedure ButtonVirtualFileInputStreamClick(Sender: TObject);
    procedure ButtonFilesRulerClick(Sender: TObject);
  private
    procedure CaptureMessageActivity(const Sender: TObject; const M: TMessage);
    procedure OnActivityResult(RequestCode, ResultCode: Integer; Data: JIntent);
    procedure ShowPdf(Uri: JNet_Uri);
    procedure ImageShowcase(Uri: JNet_Uri; Resim: TImageControl);
    procedure FileCopier_FromInternalToExternal(Dosya: string);
    procedure FileCopier_FromExternalToInternal;
    procedure Notify1(text: string);
    function TextFileReader(Uri: JNet_Uri): string;
    function FileDeleter(Uri: JNet_Uri): boolean;
    function FileName(Uri: JNet_Uri): string;
    function FileUri(Uri: JNet_Uri): JNet_Uri;
  const
    Dosya_Olustur: integer = 11; // CREATE_FILE = 1
    Pdf_Dosyasi_Sec: integer = 22; // PICK_PDF_FILE = 2
    Dizin_Agaci_Ac: integer = 33;
    Dosya_Sil: integer = 44;
    Metin_Dosyasi_Sec: integer = 55;
    Resim_Goster: integer = 66;
    Herhangi_Dosya_Sec: integer = 77;
    Dosya_Kopyala_Dahiliden_Hariciye: integer = 88;
    Dosya_Kopyala_Hariciden_Dahiliye: integer = 99;

  var
    UriCan: JNet_Uri;
    DosyaKopyalanan: string;
    KokDizin: JNet_Uri;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
  end;

var
  Form1: TForm1;

implementation

{$R *.fmx}

procedure TForm1.ButtonReadTextFileClick(Sender: TObject);
begin
  Memo1.Text := TextFileReader(UriCan);
end;

procedure TForm1.ButtonShowPdfClick(Sender: TObject);
begin
  ShowPdf(UriCan);
  Memo1.Text := 'Show PDF: ' + JStringToString(UriCan.GetPath);
end;

procedure TForm1.ButtonShowImageClick(Sender: TObject);
var
  Intent: JIntent;
begin
  Intent := TJIntent.Create;
  Intent.setAction(TJIntent.JavaClass.ACTION_OPEN_DOCUMENT)
    .addCategory(TJIntent.JavaClass.CATEGORY_OPENABLE)
    .setType(StringToJString('image/*'));
  if Intent.resolveActivity(TAndroidHelper.Context.getPackageManager) <> nil
  then
  begin
    MainActivity.startActivityForResult(Intent, Resim_Goster);
    ImageControl1.Parent := TabControl1.ActiveTab;
  end
  else
    Notify1('Image could not be obtained!');
end;

procedure TForm1.ButtonOpenAVirtualFileClick(Sender: TObject);
  function SanalDosyami(Uri: JNet_Uri): boolean; (* isVirtualFile *)
  var
    flags: integer;
    cursor: JCursor;
    s: TJavaObjectArray<JString>;
  begin
    if (not TJDocumentsContract.JavaClass.isDocumentUri(TAndroidHelper.Context,
      Uri)) then
    begin
      result := false;
      exit;
    end;
    s := TJavaObjectArray<JString>.Create(0);
    s[0] := TJDocumentsContract_Document.JavaClass.COLUMN_FLAGS;
    cursor := TAndroidHelper.Activity.getContentResolver.query(Uri, s, nil,
      nil, nil);
    flags := 0;
    if (cursor.moveToFirst) then
      flags := cursor.getInt(0);
    cursor.close;
    result := (flags and TJDocumentsContract_Document.JavaClass.
      FLAG_VIRTUAL_DOCUMENT) <> 0;
  end;
begin
  SanalDosyami(UriCan);
end;

procedure TForm1.ButtonVirtualFileInputStreamClick(Sender: TObject);
  function SanalDosyaIcinGirisAkisiAl(Uri: JNet_Uri; mimeTypeFilter: String)
    : JInputStream; (* getInputStreamForVirtualFile *)
  var
    openableMimeTypes: TJavaObjectArray<JString>;
    resolver: JContentResolver;
  begin
    resolver := TAndroidHelper.Activity.getContentResolver;
    openableMimeTypes := resolver.getStreamTypes(Uri,
      StringToJString(mimeTypeFilter));
    if ((openableMimeTypes = nil) or (openableMimeTypes.Length < 1)) then
    begin
      Notify1('File not found!');
      result := nil;
      exit;
    end;
    result := resolver.openTypedAssetFileDescriptor(Uri, openableMimeTypes[0],
      nil).createInputStream;
  end;

begin
  SanalDosyaIcinGirisAkisiAl(UriCan, '*/*');
end;

procedure TForm1.xButtonSelectPdfClick(Sender: TObject);
var
  Intent: JIntent;
begin
  Intent := TJIntent.Create;
  Intent.setAction(TJIntent.JavaClass.ACTION_OPEN_DOCUMENT);
  Intent.addCategory(TJIntent.JavaClass.CATEGORY_OPENABLE);
  Intent.setType(StringToJString('application/pdf'));
  TAndroidHelper.Activity.startActivityForResult(Intent, Pdf_Dosyasi_Sec);
end;

procedure TForm1.ButtonOpenDocumentBitProcessClick(Sender: TObject);
  function UridenBiteslemAl(Uri: JNet_Uri): JBitmap; (* getBitmapFromUri *)
  var
    fileDescriptor: JFileDescriptor;
    parcelFileDescriptor: JParcelFileDescriptor;
    image: JBitmap;
  begin
    result := nil;
    try
      parcelFileDescriptor := TAndroidHelper.Activity.getContentResolver.
        openFileDescriptor(Uri, StringToJString('r'));
      fileDescriptor := parcelFileDescriptor.getFileDescriptor;
      image := TJBitmapFactory.JavaClass.decodeFileDescriptor(fileDescriptor);
      parcelFileDescriptor.close;
      result := image;
    except
      on E: Exception do
        ShowMessage(E.Message);
    end;
  end;

var
  surf: TBitmapSurface;
  NativeBitmap: JBitmap;
begin
  NativeBitmap := UridenBiteslemAl(UriCan);
  surf := TBitmapSurface.Create;
  if JBitmapToSurface(NativeBitmap, surf) then
    ImageControl1.Bitmap.Assign(surf);
  ImageControl1.Parent := TabControl1.ActiveTab;
end;

procedure TForm1.ButtonOpenDocumentInputStreamClick(Sender: TObject);
var
  Intent: JIntent;
begin
  Intent := TJIntent.Create;
  Intent.setAction(TJIntent.JavaClass.ACTION_OPEN_DOCUMENT);
  Intent.addCategory(TJIntent.JavaClass.CATEGORY_OPENABLE);
  Intent.setType(StringToJString('text/*')); // plain')); //text/html
  TAndroidHelper.Activity.startActivityForResult(Intent, Metin_Dosyasi_Sec);
end;

procedure TForm1.ButtonEditDocumentClick(Sender: TObject);
  procedure MetinBelgesiDegistir(Uri: JNet_Uri); (* alterDocument *)
  var
    pfd: JParcelFileDescriptor;
    fileOutputStream: JFileOutputStream;
  begin
    try
      pfd := TAndroidHelper.Activity.getContentResolver.openFileDescriptor(Uri,
        StringToJString('w'));
      fileOutputStream := TJFileOutputStream.JavaClass.init
        (pfd.getFileDescriptor);
      fileOutputStream.write(StringToJString('Overwritten ' + timetostr(Now)
        ).getBytes);
      fileOutputStream.close;
      pfd.close;
    except
      on E: Exception do
        ShowMessage(E.Message); // (IOException e) e.printStackTrace;
    end;
  end;

begin
  MetinBelgesiDegistir(UriCan);
end;

procedure TForm1.ButtonInspectDocumentMetaDataClick(Sender: TObject);
  procedure GoruntuMetaVerisiDokumu(Uri: JNet_Uri); (* dumpImageMetaData *)
  // Sorgu, tek bir belgeye uyguland��� i�in, sadece tek sat�r d�nd�r�r.
  // Alanlar� filtreleme, s�ralama veya se�meye ihtiya� yoktur.
  // ��nk� t�m alanlar� bir belge i�in istiyoruz.
  var
    displayName, size: JString;
    sizeIndex: integer;
    cursor: JCursor;
  begin
    cursor := TAndroidHelper.Activity.getContentResolver.query(Uri, nil, nil,
      nil, nil, nil);
    try
      if (cursor <> nil) then
        if (cursor.moveToFirst) then
        begin
          displayName := cursor.getString
            (cursor.getColumnIndex(TJOpenableColumns.JavaClass.DISPLAY_NAME));
          Memo1.Lines.Add( { TAG.ToString + } 'Visible Name: ' +
            JStringToString(displayName));
          sizeIndex := cursor.getColumnIndex(TJOpenableColumns.JavaClass.SIZE);
          size := nil;
          if not(cursor.isNull(sizeIndex)) then
            size := cursor.getString(sizeIndex)
          else
            size := StringToJString('Unknown');
          Memo1.Lines.Add( { TAG.ToString + } 'Size: ' +
            JStringToString(size));
        end;
    finally
      cursor.close;
    end;
  end;

begin
  GoruntuMetaVerisiDokumu(UriCan);
end;

procedure TForm1.ButtonDocumentDeleteClick(Sender: TObject);
var
  Intent: JIntent;
begin
  Intent := TJIntent.Create;
  Intent.setAction(TJIntent.JavaClass.ACTION_OPEN_DOCUMENT);
  Intent.addCategory(TJIntent.JavaClass.CATEGORY_OPENABLE);
  Intent.setType(StringToJString('*/*'));
  TAndroidHelper.Activity.startActivityForResult(Intent, Dosya_Sil);
end;

procedure TForm1.ButtonAllowAccessToOneDirectoryClick(Sender: TObject);
  procedure DizinAc(YuklenecekUri: JNet_Uri);
  // Sistem dosya se�ici kullanarak bir dizin se�in
  var
    Intent: JIntent;
  begin
    Intent := TJIntent.Create;
    Intent.setAction(TJIntent.JavaClass.ACTION_OPEN_DOCUMENT_TREE);

    // �ste�e ba�l� olarak, sistem dosya se�ici y�klendi�inde
    // a��lacak dizin i�in bir URI belirleyin.
    Intent.putExtra(TJDocumentsContract.JavaClass.EXTRA_INITIAL_URI,
      JParcelable(YuklenecekUri));

    MainActivity.startActivityForResult(Intent, Dizin_Agaci_Ac);
  end;

begin
  DizinAc(KokDizin);
end;

procedure TForm1.ButtonOpenAFileClick(Sender: TObject);
// Bir PDF belgesi se�mek i�in talep kodu.
// const Pdf_Dosyasi_Sec : integer = 22;  //PICK_PDF_FILE = 2

  procedure DosyaAc(seciciBaslangicUri: JNet_Uri);
  var
    Intent: JIntent;
  begin
    Intent := TJIntent.Create;
    Intent.setAction(TJIntent.JavaClass.ACTION_OPEN_DOCUMENT);
    Intent.addCategory(TJIntent.JavaClass.CATEGORY_OPENABLE);
    Intent.setType(StringToJString('application/pdf'));

    // �ste�e ba�l� olarak, sistem dosya se�ici y�klendi�inde
    // g�sterilecek dosya i�in bir URI belirleyin.
    Intent.putExtra(TJDocumentsContract.JavaClass.EXTRA_INITIAL_URI,
      JParcelable(seciciBaslangicUri));

    MainActivity.startActivityForResult(Intent, Pdf_Dosyasi_Sec);
  end;

begin
  DosyaAc(nil);
end;

procedure TForm1.FileCopier_FromInternalToExternal(Dosya: string);
const
  bufferSize = 4096 * 2;
var
  noOfBytes: Integer;
  b: TJavaArray<Byte>;
  DosyaOku: JInputStream;
  DosyaYaz: JFileOutputStream;
  pfd: JParcelFileDescriptor;
begin
  if not FileExists(Dosya) then
  begin
    Notify1(Dosya + ' could not be found!');
    exit;
  end;
  try
    DosyaOku := TAndroidHelper.Context.getContentResolver.openInputStream
      (TJnet_Uri.JavaClass.fromFile(TJFile.JavaClass.init
      (StringToJString(Dosya))));
    pfd := TAndroidHelper.Activity.getContentResolver.openFileDescriptor(UriCan,
      StringToJString('w'));
    DosyaYaz := TJFileOutputStream.JavaClass.init(pfd.getFileDescriptor);
    b := TJavaArray<Byte>.Create(bufferSize);
    noOfBytes := DosyaOku.read(b);
    while (noOfBytes > 0) do
    begin
      DosyaYaz.write(b, 0, noOfBytes);
      noOfBytes := DosyaOku.read(b);
    end;
    DosyaYaz.close;
    DosyaOku.close;
  except
    on E: Exception do
      Application.ShowException(E);
  end;
  Notify1('File copied from Internal to External: ' + FileName(UriCan));
end;

procedure TForm1.ButtonCopyFileFromInternalToExternalClick(Sender: TObject);
(* TFile.Copy(TPath.Combine(TPath.GetDocumentsPath, 'delphican.pdf'),
  TPath.Combine(TPath.GetSharedDownloadsPath, 'delphican.pdf')); *)
  procedure PdfDosyasiOlustur(seciciBaslangicUri: JNet_Uri);
  var
    Intent: JIntent;
  begin
    Intent := TJIntent.Create;
    Intent.setAction(TJIntent.JavaClass.ACTION_CREATE_DOCUMENT);
    Intent.addCategory(TJIntent.JavaClass.CATEGORY_OPENABLE);
    Intent.setType(StringToJString('application/pdf'));
    Intent.putExtra(TJIntent.JavaClass.EXTRA_TITLE,
      StringToJString(TPath.GetFileName(DosyaKopyalanan)));
    Intent.putExtra(TJDocumentsContract.JavaClass.EXTRA_INITIAL_URI,
      JParcelable(seciciBaslangicUri));
    MainActivity.startActivityForResult(Intent,
      Dosya_Kopyala_Dahiliden_Hariciye);
  end;

begin
  DosyaKopyalanan := TPath.Combine(TPath.GetDocumentsPath, 'delphican.pdf');
  PdfDosyasiOlustur(nil);
end;

procedure TForm1.FileCopier_FromExternalToInternal;
const
  bufferSize = 4096 * 2;
var
  noOfBytes: Integer;
  b: TJavaArray<Byte>;
  DosyaOku: JInputStream;
  DosyaYaz: JFileOutputStream;
  Dosya: string;
  // pfd : JParcelFileDescriptor;
begin
  try
    Dosya := TPath.Combine(TPath.GetPublicPath, FileName(UriCan));
    if FileExists(Dosya) then
    begin
      Notify1('"' + Dosya + '" already exists!');
      exit;
    end;
    DosyaYaz := TJFileOutputStream.JavaClass.init(StringToJString(Dosya));
    DosyaOku := TAndroidHelper.Context.getContentResolver.
      openInputStream(UriCan);
    b := TJavaArray<Byte>.Create(bufferSize);
    noOfBytes := DosyaOku.read(b);
    while (noOfBytes > 0) do
    begin
      DosyaYaz.write(b, 0, noOfBytes);
      noOfBytes := DosyaOku.read(b);
    end;
    DosyaYaz.close;
    DosyaOku.close;
  except
    on E: Exception do
      Application.ShowException(E);
  end;
  Notify1('File copied from External to Internal :' + FileName(UriCan));
end;

procedure TForm1.ButtonCopyFileFromExternalToInternalClick(Sender: TObject);
(* TFile.Copy(TPath.Combine(TPath.GetSharedDownloadsPath, 'delphican.pdf'),
  TPath.Combine(TPath.GetPublicPath, 'delphican.pdf')); *)
var
  Intent: JIntent;
begin
  Intent := TJIntent.Create;
  Intent.setAction(TJIntent.JavaClass.ACTION_OPEN_DOCUMENT);
  // ACTION_GET_CONTENT);
  Intent.addCategory(TJIntent.JavaClass.CATEGORY_OPENABLE);
  Intent.setType(StringToJString('*/*'));
  TAndroidHelper.Activity.startActivityForResult(Intent,
    Dosya_Kopyala_Hariciden_Dahiliye);
end;

procedure TForm1.ButtonShareFileClick(Sender: TObject);
var
  Intent: JIntent;
  mime: JMimeTypeMap;
  ExtToMime: JString;
  ExtFile: string;
  Dosya: string;
begin
  Dosya := FileName(UriCan);
  ExtFile := AnsiLowerCase(StringReplace(TPath.GetExtension(Dosya),
    '.', '', []));
  mime := TJMimeTypeMap.JavaClass.getSingleton();
  ExtToMime := mime.getMimeTypeFromExtension(StringToJString(ExtFile));
  Intent := TJIntent.Create;
  Intent.setAction(TJIntent.JavaClass.ACTION_SEND);
  Intent.setDataAndType(UriCan, ExtToMime);
  Intent.putExtra(TJIntent.JavaClass.EXTRA_STREAM, JParcelable(UriCan));
  Intent.addFlags(TJIntent.JavaClass.FLAG_GRANT_READ_URI_PERMISSION);
  TAndroidHelper.Activity.startActivity(TJIntent.JavaClass.createChooser(Intent,
    StrToJCharSequence('Lets share: ')));
end;

procedure TForm1.ButtonGetAnyFileUriClick(Sender: TObject);
var
  Intent: JIntent;
begin
  Intent := TJIntent.Create;
  Intent.setAction(TJIntent.JavaClass.ACTION_OPEN_DOCUMENT);  // ACTION_GET_CONTENT);
  Intent.addCategory(TJIntent.JavaClass.CATEGORY_OPENABLE);
  Intent.setType(StringToJString('*/*'));
  TAndroidHelper.Activity.startActivityForResult(Intent, Herhangi_Dosya_Sec);
end;

procedure TForm1.ButtonPermanentPermissionsClick(Sender: TObject);
var
  TakeFlags: integer;
  Intent: JIntent;
begin
  Intent := TJIntent.Create;
  TakeFlags := Intent.getFlags and
    (TJIntent.JavaClass.FLAG_GRANT_READ_URI_PERMISSION or
    TJIntent.JavaClass.FLAG_GRANT_WRITE_URI_PERMISSION);
  // En yeni veriyi tetkik et
  TAndroidHelper.Activity.getContentResolver.takePersistableUriPermission
    (UriCan, TakeFlags);
end;

function TForm1.FileDeleter(Uri: JNet_Uri): boolean;
begin
  result := TJDocumentsContract.JavaClass.deleteDocument
    (TAndroidHelper.contentResolver, Uri);
end;

procedure TForm1.ButtonCreateANewFileClick(Sender: TObject);
// PDF belgesi olu�turma i�in talep kodu.
// const Dosya_Olustur : integer = 11;  //CREATE_FILE = 1

  procedure PdfDosyasiOlustur(seciciBaslangicUri: JNet_Uri);
  var
    Intent: JIntent;
  begin
    Intent := TJIntent.Create;
    Intent.setAction(TJIntent.JavaClass.ACTION_CREATE_DOCUMENT);
    Intent.addCategory(TJIntent.JavaClass.CATEGORY_OPENABLE);
    Intent.setType(StringToJString('application/pdf'));
    Intent.putExtra(TJIntent.JavaClass.EXTRA_TITLE,
      StringToJString('fatura.pdf'));

    // �ste�e ba�l� olarak, uygulaman�z dosyay� olu�turdu�unda
    // sistem dosya se�ici taraf�ndan a��lacak dizin i�in bir URI belirleyin.
    Intent.putExtra(TJDocumentsContract.JavaClass.EXTRA_INITIAL_URI,
      JParcelable(seciciBaslangicUri));
    MainActivity.startActivityForResult(Intent, Dosya_Olustur);
  end;

var
  SeciciBaslangicUri_: JNet_Uri;
begin
  SeciciBaslangicUri_ := KokDizin;
  // TJnet_Uri.JavaClass.fromFile(TJFile.JavaClass.init(StringToJString( TPath.GetSharedDownloadsPath)));
  PdfDosyasiOlustur(SeciciBaslangicUri_);
end;

constructor TForm1.Create(AOwner: TComponent);
const
  Authority: string = 'com.android.externalstorage.documents';
begin
  inherited;
  TMessageManager.DefaultManager.SubscribeToMessage(TMessageResultNotification,
    CaptureMessageActivity);
  try
    TabControl1.ActiveTab := tiUriAl;
    Memo1.Lines.Add('Android ' + JStringToString
      (TJBuild_VERSION.JavaClass.RELEASE) + '   ' + 'SDK ' +
      inttostr(TJBuild_VERSION.JavaClass.SDK_INT) + sLineBreak +
      JStringToString(TJBuild.JavaClass.BRAND) + '  ' +
      JStringToString(TJBuild.JavaClass.MODEL) + '  ' +
      JStringToString(TJBuild.JavaClass.CPU_ABI) + '  ' +
      JStringToString(TJBuild.JavaClass.BOARD));
    KokDizin := TJDocumentsContract.JavaClass.buildTreeDocumentUri
      (StringToJString(Authority), StringToJString('primary:')); // roottree
  finally
  end;
end;

destructor TForm1.Destroy;
begin
  TMessageManager.DefaultManager.Unsubscribe(TMessageResultNotification,
    CaptureMessageActivity);
  inherited;
end;

procedure TForm1.CaptureMessageActivity(const Sender: TObject; const M: TMessage);
begin
  if M is TMessageResultNotification then
    OnActivityResult(TMessageResultNotification(M).RequestCode,
      TMessageResultNotification(M).ResultCode,
      TMessageResultNotification(M).Value);
end;

procedure TForm1.OnActivityResult(RequestCode, ResultCode: Integer;
  Data: JIntent);
var
  Uri: JNet_Uri;
  Ad: string;
begin
  Memo1.Lines.Clear;
  if ResultCode = TJActivity.JavaClass.RESULT_OK then
  begin
    // Sonu� verisi kullan�c�n�n se�ti�i
    // belge veya dizin i�in bir URI i�erir.
    Uri := nil;
    if Assigned(Data) then
    begin
      if (Data = nil) then
      begin
        Memo1.Lines.Add('Uri could not be obtained!');
        exit;
      end;
      Uri := Data.getData;
      UriCan := Uri;
      Ad := '"' + FileName(Uri) + '" ';
      // (' + TPath.GetFileName(JStringToString(uri.getPath) + ') ');

      // URI�sini kullanarak belge �zerinde i�lemler ger�ekle�tirin.
      if RequestCode = Dosya_Olustur then
      begin
        Notify1('New pdf file created : ' + Ad);
      end;
      if RequestCode = Pdf_Dosyasi_Sec then
      begin
        ShowPdf(Uri);
        Notify1('Read Pdf file: ' + Ad);
      end;
      if RequestCode = Dizin_Agaci_Ac then
      begin
        Notify1('Access granted to files in directory: ' + Ad);
      end;
      if RequestCode = Dosya_Sil then
      begin
        FileDeleter(Uri);
        Notify1(Ad + 'deleted');
        UriCan := nil;
      end;
      if RequestCode = Metin_Dosyasi_Sec then
      begin
        Notify1('Read text file: ' + Ad + sLineBreak +
          TextFileReader(Uri));
      end;
      if RequestCode = Resim_Goster then
      begin
        ImageShowcase(Uri, ImageControl1);
        Notify1('Show image: ' + Ad);
      end;
      if RequestCode = Herhangi_Dosya_Sec then
      begin
        Notify1('File selected: ' + Ad);
      end;
      if RequestCode = Dosya_Kopyala_Dahiliden_Hariciye then
      begin
        FileCopier_FromInternalToExternal(DosyaKopyalanan);
      end;
      if RequestCode = Dosya_Kopyala_Hariciden_Dahiliye then
      begin
        FileCopier_FromExternalToInternal;
      end;
    end;
    Memo1.Lines.Add(' ');
    Memo1.GoToTextEnd;
  end
  else if ResultCode = TJActivity.JavaClass.RESULT_CANCELED then
  begin
    Notify1('Activity cancelled!');
  end;
  if UriCan <> nil then
    MemoUri.Text := JStringToString(UriCan.toString)
  else
    MemoUri.Text := '';
end;

procedure TForm1.TabControl1Change(Sender: TObject);
begin
  Panel1.Parent := TabControl1.ActiveTab;
end;

procedure TForm1.Notify1(text: string);
begin
  Memo1.Lines.Add(text + sLineBreak);
  Application.ProcessMessages;
  TThread.Synchronize(nil,
    procedure
    begin
      TJToast.JavaClass.makeText(TAndroidHelper.Context,
        StrToJCharSequence(text), TJToast.JavaClass.LENGTH_LONG).show;
    end);
end;

function TForm1.FileName(Uri: JNet_Uri): string;
var
  C: JCursor;
begin
  result := '';
  try
    C := TAndroidHelper.Activity.getContentResolver.query(Uri, nil, nil,
      nil, nil, nil);
    if (C = nil) then
      exit;
    C.moveToFirst;
    result := JStringToString
      (C.getString(C.getColumnIndex(TJOpenableColumns.JavaClass.DISPLAY_NAME)));
  finally
    C.close;
  end;
end;

function TForm1.FileUri(Uri: JNet_Uri): JNet_Uri;
var
  C: JCursor;
  DosyaYolu : JString;
begin
  result := nil;
  try
    C := TAndroidHelper.Activity.getContentResolver.query(Uri, nil, nil,
      nil, nil, nil);
    if (C = nil) then
      exit;
    C.moveToFirst;
    DosyaYolu := C.getString(0);
   //LUri := TAndroidHelper.JFileToJURI(TJFile.JavaClass.init(StringToJString(FileName(UriCan)))); // StringToJString(AFileName)));
    result := TAndroidHelper.JFileToJURI(TJFile.JavaClass.init(DosyaYolu)); //JStringToString(C.getString(C.getColumnIndex(TJOpenableColumns.JavaClass.DISPLAY_NAME)));
  finally
    C.close;
  end;
end;

procedure TForm1.ButtonFilesRulerClick(Sender: TObject);
var
  FileList: TStringDynArray;
  DocDir, FFile, s: string;
begin
  with Memo1 do
  begin
    DocDir := TPath.GetHomePath;
    Text := ('GetHomePath :');
    FileList := TDirectory.GetFiles(DocDir);
    for s in FileList do
      Lines.Add(TPath.GetFileName(s));
    DocDir := TPath.GetPublicPath;
    Lines.Add(sLineBreak + 'GetPublicPath :');
    FileList := TDirectory.GetFiles(DocDir);
    for s in FileList do
      Lines.Add(TPath.GetFileName(s));
    FFile := 'delphican.pdf';
    Lines.Add(' ');
    if (FileExists(TPath.Combine(TPath.GetDocumentsPath, FFile))) then
      Lines.Add(FFile + ' exists in the internal folder')
    else
      Lines.Add(FFile + ' does not exist in the internal folder');
    FFile := 'delphican.pdf';
    if (FileExists(TPath.Combine(TPath.GetSharedDownloadsPath, FFile))) then
      Lines.Add(FFile + ' exists in the external folder')
    else
      Lines.Add(FFile + ' does not exist in the external folder');
    Lines.Add(' ');
    GoToTextEnd;
  end;
end;

procedure TForm1.MemoUriTap(Sender: TObject; const Point: TPointF);
begin
  if UriCan <> nil then
    MemoUri.Text := JStringToString(UriCan.toString)
  else
    MemoUri.Text := '';
end;

function TForm1.TextFileReader(Uri: JNet_Uri): string;
(* readTextFromUri *)
const
  bufferSize = 4096 * 2;
var
  inputStream: JInputStream;
  b: TJavaArray<Byte>;
  ms: TMemoryStream;
  sl: TStringList;
  bufflen: Integer;
begin
  result := '';
  try
    inputStream := TAndroidHelper.Context.getContentResolver.
      openInputStream(Uri);
    ms := TMemoryStream.Create;
    bufflen := inputStream.available;
    b := TJavaArray<Byte>.Create(bufflen);
    inputStream.read(b);
    ms.write(b.Data^, bufflen);
    ms.position := 0;
    sl := TStringList.Create;
    sl.LoadFromStream(ms);
    result := sl.Text;
    sl.Free;
    b.Free;
    ms.Free;
    inputStream.close;
  except
    on E: Exception do
      Application.ShowException(E);
  end;
end;

procedure TForm1.ShowPdf(Uri: JNet_Uri);
var
  Intent: JIntent;
begin
  Intent := TJIntent.Create;
  Intent := TJIntent.JavaClass.init(TJIntent.JavaClass.ACTION_VIEW);
  Intent.setDataAndType(UriCan, StringToJString('application/pdf'));
  Intent.putExtra(TJIntent.JavaClass.EXTRA_STREAM, JParcelable(UriCan));
  Intent.addFlags(TJIntent.JavaClass.FLAG_GRANT_READ_URI_PERMISSION);
  TAndroidHelper.Activity.startActivity(Intent);
end;

procedure TForm1.ImageShowcase(Uri: JNet_Uri; Resim: TImageControl);
  procedure GetEXIF(const AFileName: JInputStream);
  var
    LEXIF: JExifInterface;
    LLatLong: TJavaArray<Single>;
  begin
    try
      LEXIF := TJExifInterface.JavaClass.init(AFileName);
      Memo1.Lines.Add('Date Taken: ' +
        JStringToString(LEXIF.getAttribute
        (TJExifInterface.JavaClass.TAG_DATETIME)));
      Memo1.Lines.Add('Camera Make: ' +
        JStringToString(LEXIF.getAttribute
        (TJExifInterface.JavaClass.TAG_MAKE)));
      Memo1.Lines.Add('Camera Model: ' +
        JStringToString(LEXIF.getAttribute
        (TJExifInterface.JavaClass.TAG_MODEL)));
      LLatLong := TJavaArray<Single>.Create(2);
      try
        if LEXIF.getLatLong(LLatLong) then
        begin
          Memo1.Lines.Add('Latitude: ' + LLatLong.Items[0].toString);
          Memo1.Lines.Add('Longitude: ' + LLatLong.Items[1].toString);
        end;
      finally
        LLatLong.Free;
      end;
    except
      on E: Exception do
        ShowMessage(E.Message);
    end;
    Memo1.GoToTextEnd;
  end;

var
  FullPhotoUri: JNet_Uri;
  jis: JInputStream;
  NativeBitmap: JBitmap;
  surf: TBitmapSurface;
begin
  try
    try
      FullPhotoUri := Uri;
      jis := TAndroidHelper.Context.getContentResolver.openInputStream
        (FullPhotoUri);
      GetEXIF(jis);
      jis.close;
      jis := TAndroidHelper.Context.getContentResolver.openInputStream
        (FullPhotoUri);
      NativeBitmap := TJBitmapFactory.JavaClass.decodeStream(jis);
      surf := TBitmapSurface.Create;
      if JBitmapToSurface(NativeBitmap, surf) then
        ImageControl1.Bitmap.Assign(surf);
    except
      on E: Exception do
        Application.ShowException(E);
    end;
  finally
    jis.close;
  end; // https://stackoverflow.com/questions/60155948/deplhi-trying-to-get-exif-data-on-library-images-in-android
end;

end.
