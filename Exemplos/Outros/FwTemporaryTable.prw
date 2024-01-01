#include 'protheus.ch'

User Function FwTemporaryTable()
	Private aFields := {}
	Private oTempTable
    
    cTable := criaTmp()
    populaTmp(cTable)
    oTable:GetRealName()
    //  deleção da tabela temporária
    //  Esse método chama de forma automática a função DbCloseArea para fechar o seu alias.
    oTempTable:Delete()    

    // Elimina da memória a instância do objeto informado como parâmetro. 
    FreeObj(oTempTable)    

Return


Function criaTmp()
    Local cAliasTmp := GetNextAlias()
    // Crio com array com os campos da tabela
    aAdd(aFields, {'TMP_CLIENT', TamSx3('E1_CLIENTE')[3]   , TamSx3('E1_CLIENTE')[1]   , 0})    
    aAdd(aFields, {'TMP_NUM'   , TamSx3('E1_NUM')[3]       , TamSx3('E1_NUM')[1]       , 0})
    aAdd(aFields, {'TMP_PARCEL', TamSx3('E1_PARCELA')[3]   , TamSx3('E1_PARCELA')[1]   , 0})
    aAdd(aFields, {'TMP_VALOR' , TamSx3('E1_VALOR')[3]     , TamSx3('E1_VALOR')[1]     , TamSx3('E1_VALOR')[2]})

    oTempTable := FWTemporaryTable():New( cAliasTmp, aFields )    
    oTable:AddIndex('01', {'TMP_FILIAL','TMP_PREFIX','TMP_NUM','TMP_PARCEL'})
    oTempTable:Create()    

Return oTempTable:GetAlias()


Function populaTmp(cAliasTmp)
    Local cAliasSE1 := GetNextAlias()
    
    // Faço uma consulta SQL dos dados que desejo popular
    BeginSql Alias cAliasSE1     
        %NoParser%
        SELECT
            SE1.E1_CLIENTE,
            SE1.E1_NUM,
            SE1.E1_PARCELA,
            SE1.E1_VALOR,
        FROM %TABLE:SE1% (NOLOCK) SE1
        WHERE
            SE1.E1_SALDO > 0 AND
            DATEDIFF(DAY,SE1.E1_EMISSAO,CONVERT(DATE,GETDATE())) > 1 AND
            SE1.%NOTDEL%             
    EndSQL    

    (cAliasSE1)->(DbGoTop())
     
    DbSelectArea(cAliasTmp)

    // Insiro todos os dados da consulta na minha tabela temporaria
    While(!(cAliasSE1)->(EoF()))
      
        RecLock(cAliasTmp, .T.)
            (cAliasTmp)->TMP_CLIENT := (cAliasSE1)->E1_CLIENTE
            (cAliasTmp)->TMP_NUM    := (cAliasSE1)->E1_NUM
            (cAliasTmp)->TMP_PARCEL := (cAliasSE1)->E1_PARCELA
            (cTable)->TMP_VALOR  := Round((cAliasSE1)->E1_VALOR,2)
        (cAliasTmp)->(MsUnlock())
         
        (cAliasSE1)->(DbSkip())
         
    EndDo        

    (cAliasTmp)->(DbGoTop())
     
    (cAliasSE1)->(DbCloseArea())

Return 
