unit uPrincipal;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, IdComponent,
  IdTCPConnection, IdTCPClient, IdHTTP, IdBaseComponent, IdAntiFreezeBase,
  IdAntiFreeze, Vcl.ComCtrls, util.download, Vcl.Buttons, IdIOHandler,
  IdIOHandlerSocket, IdIOHandlerStack, IdSSL, IdSSLOpenSSL, FireDAC.Stan.Intf,
  FireDAC.Stan.Option, FireDAC.Stan.Error, FireDAC.UI.Intf, FireDAC.Phys.Intf,
  FireDAC.Stan.Def, FireDAC.Stan.Pool, FireDAC.Stan.Async, FireDAC.Phys,
  FireDAC.Phys.SQLite, FireDAC.Phys.SQLiteDef, FireDAC.Stan.ExprFuncs,
  FireDAC.VCLUI.Wait, Data.DB, FireDAC.Comp.Client, dxGDIPlusClasses,
  Vcl.ExtCtrls;

type
  TfrmPrincipal = class(TForm)
    IdAntiFreeze: TIdAntiFreeze;
    IdHTTP: TIdHTTP;
    dlgSave: TSaveDialog;
    edtUrl: TEdit;
    Label1: TLabel;
    ckbOpcao: TCheckBox;
    btnIniciar: TButton;
    btnParar: TButton;
    Button3: TButton;
    pbprogresso: TProgressBar;
    IdSSLIOHandlerSocketOpenSSL1: TIdSSLIOHandlerSocketOpenSSL;
    lblStatus: TLabel;
    Image1: TImage;
    Label2: TLabel;
    btnHistorico: TButton;
    procedure Button3Click(Sender: TObject);
    procedure btnPararClick(Sender: TObject);
    procedure btnIniciarClick(Sender: TObject);
    procedure IdHTTPWork(ASender: TObject; AWorkMode: TWorkMode;
      AWorkCount: Int64);
    procedure IdHTTPWorkBegin(ASender: TObject; AWorkMode: TWorkMode;
      AWorkCountMax: Int64);
    procedure IdHTTPWorkEnd(ASender: TObject; AWorkMode: TWorkMode);
    procedure btnHistoricoClick(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
  private
    zIniciou : Boolean;

    function RetornaPorcentagem(ValorMaximo, ValorAtual: real): string;
    function RetornaKiloBytes(ValorAtual: real): string;
  public
    { Public declarations }
  end;

var
  frmPrincipal: TfrmPrincipal;

implementation

uses
  Ctrl.Download, uHistorico;

{$R *.dfm}

procedure TfrmPrincipal.btnIniciarClick(Sender: TObject);
var
 fileDownload : TFileStream;
 zConexao : TDownload_ctrl;
begin
  dlgSave.Filter := 'Arquivos' + ExtractFileExt(edtUrl.Text) + '|*' + ExtractFileExt(edtUrl.Text);
  dlgSave.FileName := 'VSCOLD';
  if dlgSave.Execute then
    begin
      fileDownload := TFileStream.Create(dlgSave.FileName + ExtractFileExt(edtUrl.Text), fmCreate);

      zConexao :=  TDownload_ctrl.Create;
      try
        btnIniciar.Enabled := False;
        btnParar.Enabled := True;
        zConexao.Get;
        //ShowMessage(IntToStr(zConexao.conexao.qTemp.RecordCount));
        zConexao.Model.Codigo := zConexao.conexao.qTemp.RecordCount+1;
        zConexao.Model.Url := edtUrl.Text;
        zConexao.Model.DataInical := now;

        pbprogresso.Visible := True;
        lblStatus.Visible   := True;
        Try
          IdHTTP.Get(edtUrl.Text, fileDownload);
        Except
          On e : Exception do
           begin
             Application.MessageBox(pchar('Não foi possível baixar o arquivo.'+sLineBreak+
                         ' Motivo: '+e.Message), 'Atenção', MB_OK + MB_ICONINFORMATION);
             Exit;
           end;
        End;

        zConexao.Model.DataFinal := now;
        zConexao.conexao.FDConexao.StartTransaction;
        if zConexao.insert then
          zConexao.conexao.FDConexao.Commit
        else
          zConexao.conexao.FDConexao.Rollback;

      finally
        FreeAndNil(zConexao);
        FreeAndNil(fileDownload);
      end;
   end;
end;

procedure TfrmPrincipal.btnHistoricoClick(Sender: TObject);
begin
  Try
    Application.CreateForm(TfrmHistorico, frmHistorico);
    frmHistorico.ShowModal;
  Finally
    FreeAndNil(frmHistorico);
  End;
end;

procedure TfrmPrincipal.btnPararClick(Sender: TObject);
begin
  if (MessageDlg('Existe um download em andamento, deseja interrompe-lo?', mtConfirmation,[ mbYes,MbNo ], 0) = mrYes) then
    IdHTTP.Disconnect;
end;

procedure TfrmPrincipal.Button3Click(Sender: TObject);
begin
  Close;
end;


procedure TfrmPrincipal.FormCloseQuery(Sender: TObject; var CanClose: Boolean);
begin
  if (zIniciou) And
     (MessageDlg('Existe um download em andamento, deseja interrompe-lo?', mtConfirmation,[ mbYes,MbNo ], 0) = mrYes) then
   IdHTTP.Disconnect
  else
    CanClose := not zIniciou;
end;

procedure TfrmPrincipal.FormShow(Sender: TObject);
begin
  zIniciou := False;
end;

procedure TfrmPrincipal.IdHTTPWork(ASender: TObject; AWorkMode: TWorkMode;
  AWorkCount: Int64);
begin
  pbprogresso.Position := AWorkCount;
  lblStatus.Caption    := 'Baixando ... ' + RetornaKiloBytes(AWorkCount);
  frmPrincipal.Caption := 'Download em ... ' + RetornaPorcentagem(pbprogresso.Max, AWorkCount);
end;

procedure TfrmPrincipal.IdHTTPWorkBegin(ASender: TObject; AWorkMode: TWorkMode;
  AWorkCountMax: Int64);
begin
  zIniciou := True;
  pbprogresso.Max := AWorkCountMax;
end;

procedure TfrmPrincipal.IdHTTPWorkEnd(ASender: TObject; AWorkMode: TWorkMode);
begin
  zIniciou := False;
  pbprogresso.Position := 0;
  frmPrincipal.Caption := 'Download Finalizado ...';
  lblStatus.Caption    := 'Download Finalizado ...';
  pbprogresso.Visible  := false;
  btnIniciar.Enabled   := true;
  btnParar.Enabled     := False;

  if ckbOpcao.Checked then
    Application.Terminate;
end;

function TfrmPrincipal.RetornaKiloBytes(ValorAtual: real): string;
var
  resultado : real;
begin
  resultado := ((ValorAtual / 1024) / 1024);
  Result    := FormatFloat('0.000 KBs', resultado);
end;

function TfrmPrincipal.RetornaPorcentagem(ValorMaximo, ValorAtual: real): string;
var
  resultado: Real;
begin
  resultado := ((ValorAtual * 100) / ValorMaximo);
  Result    := FormatFloat('0%', resultado);
end;

end.


