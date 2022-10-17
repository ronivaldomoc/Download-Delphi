program Downloads;

uses
  Vcl.Forms,
  uPrincipal in 'uPrincipal.pas' {frmPrincipal},
  util.download in 'util.download.pas',
  ctrl.conexao in 'ctrl\ctrl.conexao.pas',
  ctrl.Download in 'ctrl\ctrl.Download.pas',
  Model.Download in 'model\Model.Download.pas',
  uHistorico in 'view\uHistorico.pas' {frmHistorico};

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TfrmPrincipal, frmPrincipal);
  Application.Run;
end.
