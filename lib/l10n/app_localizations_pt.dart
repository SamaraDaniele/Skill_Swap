// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Portuguese (`pt`).
class AppLocalizationsPt extends AppLocalizations {
  AppLocalizationsPt([String locale = 'pt']) : super(locale);

  @override
  String get appTitle => 'Skill Swap';

  @override
  String get authTagline => 'Ensine o que sabe. Aprenda o que ama.';

  @override
  String get signInTitle => 'Bem-vindo de volta';

  @override
  String get signUpTitle => 'Crie sua conta';

  @override
  String get emailLabel => 'E-mail';

  @override
  String get passwordLabel => 'Senha';

  @override
  String get signInAction => 'Entrar';

  @override
  String get signUpAction => 'Criar conta';

  @override
  String get newHerePrompt => 'Novo por aqui?';

  @override
  String get haveAccountPrompt => 'Já tem conta?';

  @override
  String get forgotPassword => 'Esqueci minha senha';

  @override
  String get orSeparator => 'ou';

  @override
  String get continueWithGoogle => 'Continuar com Google';

  @override
  String get continueWithApple => 'Continuar com Apple';

  @override
  String get socialSignInSoon =>
      'Essa opção de login chega em breve. Por enquanto, use e-mail e senha.';

  @override
  String get resetPasswordTitle => 'Recuperar senha';

  @override
  String get resetPasswordBody =>
      'Informe seu e-mail e enviaremos um link para criar uma nova senha.';

  @override
  String get resetPasswordSent =>
      'Se existir uma conta com esse e-mail, o link chega em instantes.';

  @override
  String get showPassword => 'Mostrar senha';

  @override
  String get hidePassword => 'Ocultar senha';

  @override
  String get validationEmail => 'Informe um e-mail válido';

  @override
  String get validationPassword => 'Use pelo menos 6 caracteres';

  @override
  String get validationRequired => 'Campo obrigatório';

  @override
  String get validationPickSkill => 'Escolha pelo menos uma habilidade';

  @override
  String get errorTitle => 'Algo deu errado';

  @override
  String get errorInvalidCredentials => 'E-mail ou senha incorretos.';

  @override
  String get errorEmailInUse => 'Este e-mail já está cadastrado.';

  @override
  String get errorWeakPassword => 'Escolha uma senha mais forte.';

  @override
  String get errorNetwork =>
      'Sem conexão. Verifique sua internet e tente novamente.';

  @override
  String get errorTooManyRequests =>
      'Muitas tentativas. Aguarde alguns minutos e tente de novo.';

  @override
  String get errorPermission => 'Você não tem permissão para esta ação.';

  @override
  String get errorInvalidImage =>
      'Não foi possível usar esta imagem. Tente outra foto.';

  @override
  String get errorUnknown => 'Algo deu errado. Tente novamente.';

  @override
  String get retryAction => 'Tentar novamente';

  @override
  String get profileSetupTitle => 'Monte seu perfil';

  @override
  String get profileSetupSubtitle =>
      'Conte o que você pode ensinar e o que quer aprender.';

  @override
  String get editProfileTitle => 'Editar perfil';

  @override
  String get nameLabel => 'Nome';

  @override
  String get bioLabel => 'Sobre você';

  @override
  String get bioHint =>
      'Uma breve apresentação, disponibilidade, formato preferido…';

  @override
  String get photoAddAction => 'Adicionar foto';

  @override
  String get photoChangeAction => 'Trocar foto';

  @override
  String get photoRemoveAction => 'Remover foto';

  @override
  String get photoProcessing => 'Preparando foto…';

  @override
  String get photoHint =>
      'Opcional. Usamos um recorte quadrado da foto e removemos dados de localização.';

  @override
  String get teachSectionTitle => 'Posso ensinar';

  @override
  String get learnSectionTitle => 'Quero aprender';

  @override
  String get saveAction => 'Salvar';

  @override
  String get profileSaved => 'Perfil salvo';

  @override
  String get navDiscover => 'Match';

  @override
  String get navMatches => 'Conversas';

  @override
  String get navProfile => 'Perfil';

  @override
  String get discoverEmptyTitle => 'Ninguém novo por enquanto';

  @override
  String get discoverEmptyBody =>
      'Adicione mais habilidades ao seu perfil ou volte mais tarde.';

  @override
  String get refreshAction => 'Atualizar';

  @override
  String get likeAction => 'Tenho interesse';

  @override
  String get passAction => 'Pular';

  @override
  String get teachesLabel => 'Ensina';

  @override
  String get wantsLabel => 'Quer aprender';

  @override
  String compatibility(int percent) {
    return '$percent% compatível';
  }

  @override
  String get matchDialogTitle => 'Deu match!';

  @override
  String matchDialogBody(String name) {
    return 'Você e $name já podem conversar.';
  }

  @override
  String get openChatAction => 'Enviar mensagem';

  @override
  String get keepExploringAction => 'Continuar explorando';

  @override
  String get matchesEmptyTitle => 'Nenhum match ainda';

  @override
  String get matchesEmptyBody =>
      'Demonstre interesse em perfis em Descobrir. Quando for recíproco, eles aparecem aqui.';

  @override
  String get matchesNoMessages => 'Diga oi para começar a troca';

  @override
  String get chatHint => 'Mensagem';

  @override
  String get sendAction => 'Enviar';

  @override
  String get chatEmpty =>
      'Combinem os assuntos, o formato e um horário bom para os dois.';

  @override
  String get signOutAction => 'Sair';

  @override
  String get editProfileAction => 'Editar perfil';

  @override
  String get skillExcel => 'Excel';

  @override
  String get skillEnglish => 'Inglês';

  @override
  String get skillSpanish => 'Espanhol';

  @override
  String get skillProgramming => 'Programação';

  @override
  String get skillPython => 'Python';

  @override
  String get skillGuitar => 'Violão';

  @override
  String get skillPiano => 'Piano';

  @override
  String get skillMath => 'Matemática';

  @override
  String get skillPhysics => 'Física';

  @override
  String get skillChemistry => 'Química';

  @override
  String get skillPhotoEditing => 'Edição de imagens';

  @override
  String get skillVideoEditing => 'Edição de vídeo';

  @override
  String get skillCooking => 'Culinária';

  @override
  String get skillCrafts => 'Artesanato';

  @override
  String get skillDrawing => 'Desenho';

  @override
  String get skillWriting => 'Redação';

  @override
  String get skillPublicSpeaking => 'Oratória';

  @override
  String get skillPhotography => 'Fotografia';

  @override
  String get skillDesign => 'Design';

  @override
  String get skillMarketing => 'Marketing';

  @override
  String get moreOptions => 'Mais opções';

  @override
  String get cancelAction => 'Cancelar';

  @override
  String get unmatchAction => 'Desfazer match';

  @override
  String get unmatchConfirmTitle => 'Desfazer este match?';

  @override
  String get unmatchConfirmBody =>
      'A conversa será encerrada para vocês dois. Não dá para desfazer.';

  @override
  String get matchClosedDone => 'Match desfeito';

  @override
  String get blockAction => 'Bloquear';

  @override
  String blockConfirmTitle(String name) {
    return 'Bloquear $name?';
  }

  @override
  String get blockConfirmBody =>
      'Vocês não darão match de novo e nenhuma mensagem poderá ser enviada. Não dá para desfazer.';

  @override
  String get blockDone => 'Perfil bloqueado';

  @override
  String get reportAction => 'Denunciar';

  @override
  String get reportProfileTooltip => 'Denunciar perfil';

  @override
  String reportTitle(String name) {
    return 'Denunciar $name';
  }

  @override
  String get reportIntro =>
      'Sua denúncia é confidencial. O perfil também será bloqueado para você.';

  @override
  String get reportReasonHarassment => 'Assédio ou ameaças';

  @override
  String get reportReasonSpam => 'Spam';

  @override
  String get reportReasonInappropriate => 'Conteúdo impróprio';

  @override
  String get reportReasonFake => 'Perfil falso';

  @override
  String get reportReasonOther => 'Outro motivo';

  @override
  String get reportDetailsLabel => 'Detalhes (opcional)';

  @override
  String get reportPickReason => 'Escolha um motivo';

  @override
  String get reportSubmitAction => 'Denunciar e bloquear';

  @override
  String get reportDone =>
      'Denúncia enviada. Obrigado por ajudar a manter a comunidade segura.';

  @override
  String get chatClosedNotice => 'Esta conversa foi encerrada.';

  @override
  String get consentTitle => 'Antes de continuar';

  @override
  String get consentBody =>
      'O Skill Swap conecta pessoas que querem trocar conhecimento. Para manter todos seguros, os membros precisam ser maiores de idade e seguir as regras da comunidade.';

  @override
  String get consentCheckbox =>
      'Tenho 18 anos ou mais e aceito os Termos e as Regras da comunidade';

  @override
  String get consentRequired => 'É preciso aceitar para continuar';

  @override
  String get continueAction => 'Continuar';

  @override
  String get readTermsAction => 'Ler os termos';

  @override
  String get termsTitle => 'Termos e regras da comunidade';

  @override
  String get termsBody =>
      '• É preciso ter 18 anos ou mais.\n• Trate todos com respeito: assédio, ameaças, discurso de ódio e conteúdo sexual não são permitidos.\n• Use seu nome real e descreva suas habilidades com honestidade.\n• Nada de spam, golpes ou cobranças escondidas.\n• Não compartilhe dados pessoais de outras pessoas.\n• Prefira lugares públicos ou chamadas de vídeo para os encontros.\n\nVocê pode desfazer um match, bloquear ou denunciar qualquer pessoa pelo menu da conversa ou pelo cartão do perfil. As denúncias são confidenciais e analisadas pela equipe do projeto; descumprir estas regras pode levar à remoção da conta.\n\nEste texto é um resumo feito para um projeto acadêmico e não substitui termos de uso revisados juridicamente.';

  @override
  String get matchTitle => 'Match';

  @override
  String get notificationsSoon => 'Notificações (em breve)';

  @override
  String get openProfile => 'Seu perfil';

  @override
  String get undoAction => 'Desfazer último pulo';

  @override
  String get saveForLaterSoon => 'Salvar para depois (em breve)';

  @override
  String get knowledgeMatchTitle => 'Match de Conhecimento';

  @override
  String knowledgeExchange(String teach, String learn, String name) {
    return 'Você ensina $teach e aprende $learn com $name.';
  }

  @override
  String knowledgeTeach(String skill, String name) {
    return 'Você sabe $skill e $name quer aprender!';
  }

  @override
  String knowledgeLearn(String name, String skill) {
    return '$name sabe $skill, que você quer aprender!';
  }

  @override
  String skillPair(String first, String second) {
    return '$first e $second';
  }

  @override
  String profileCardLabel(String name) {
    return 'Perfil de $name';
  }

  @override
  String get navMySkills => 'Minhas Skills';

  @override
  String get goalLabel => 'Objetivo';

  @override
  String goalLearn(String skill) {
    return 'Aprender $skill';
  }

  @override
  String get compatibilityLabel => 'Afinidade';

  @override
  String get profileDetailsAction => 'Ver detalhes do perfil';

  @override
  String newMatchesBadge(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count matches sem conversa',
      one: '1 match sem conversa',
    );
    return '$_temp0';
  }

  @override
  String get navCommunity => 'Comunidade';

  @override
  String get communityTitle => 'Comunidade';

  @override
  String get communitySubtitle => 'Compartilhe, aprenda e inspire.';

  @override
  String get searchAction => 'Pesquisar';

  @override
  String get newPostAction => 'Nova publicação';

  @override
  String get notificationsTitle => 'Notificações';

  @override
  String unreadBadge(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count não lidas',
      one: '1 não lida',
    );
    return '$_temp0';
  }

  @override
  String get feedForYou => 'Para você';

  @override
  String get feedFollowing => 'Seguindo';

  @override
  String get feedSkills => 'Skills';

  @override
  String get feedProjects => 'Projetos';

  @override
  String get feedEmptyTitle => 'Nenhuma publicação ainda';

  @override
  String get feedEmptyBody =>
      'Seja a primeira pessoa a compartilhar um projeto, uma dica ou uma dúvida.';

  @override
  String get feedFollowingEmptyTitle => 'Nada de quem você segue';

  @override
  String get feedFollowingEmptyBody =>
      'Siga outros membros para ver as publicações deles aqui.';

  @override
  String get feedSkillsEmptyTitle =>
      'Nenhuma publicação sobre suas habilidades';

  @override
  String get feedSkillsEmptyBody =>
      'Publicações sobre o que você ensina ou quer aprender aparecem aqui.';

  @override
  String get feedProjectsEmptyTitle => 'Nenhum projeto ainda';

  @override
  String get feedProjectsEmptyBody =>
      'Mostre o que você criou: publique um projeto.';

  @override
  String get searchPeopleAction => 'Encontrar pessoas';

  @override
  String get feedEnd => 'Você viu tudo por enquanto';

  @override
  String get loadMoreFailed =>
      'Não foi possível carregar mais. Toque para tentar de novo';

  @override
  String get loadMoreAction => 'Carregar mais';

  @override
  String get loadingPosts => 'Carregando publicações';

  @override
  String get timeNow => 'agora';

  @override
  String timeMinutes(int n) {
    return 'há $n min';
  }

  @override
  String timeHours(int n) {
    return 'há $n h';
  }

  @override
  String timeDays(int n) {
    return 'há $n d';
  }

  @override
  String get postTypeProject => 'Projeto';

  @override
  String get postTypeTip => 'Dica';

  @override
  String get postTypeQuestion => 'Dúvida';

  @override
  String get postTypeAchievement => 'Conquista';

  @override
  String get postTypeWork => 'Trabalho';

  @override
  String hashtagSemantics(String tag) {
    return 'Hashtag $tag';
  }

  @override
  String get memberFallbackName => 'Membro';

  @override
  String teachesSkill(String skill) {
    return 'Ensina $skill';
  }

  @override
  String openMemberProfile(String name) {
    return 'Abrir perfil de $name';
  }

  @override
  String get postEdited => 'editado';

  @override
  String get postMenuTooltip => 'Opções da publicação';

  @override
  String get readMore => 'Ver mais';

  @override
  String postImageSemantics(int index, int total) {
    return 'Imagem $index de $total';
  }

  @override
  String get imageLoadFailed => 'Toque para tentar de novo';

  @override
  String get learnPanelTitle => 'Habilidade disponível para ensinar';

  @override
  String learnPanelBody(String name, String skills) {
    return '$name pode ensinar $skills.';
  }

  @override
  String learnWithAction(String name) {
    return 'Quero aprender com $name';
  }

  @override
  String get learnPending => 'Interesse enviado · aguardando resposta';

  @override
  String learnConfirmTitle(String name) {
    return 'Aprender com $name?';
  }

  @override
  String learnConfirmBody(String name) {
    return 'Isso envia seu interesse pelo Match, como deslizar para a direita. $name será notificado(a) de que você quer aprender a partir desta publicação. Se $name também tiver interesse em você, vocês dão match e a conversa é liberada.';
  }

  @override
  String get learnConfirmAction => 'Enviar interesse';

  @override
  String learnSent(String name) {
    return 'Interesse enviado para $name. Vocês darão match se o interesse for mútuo.';
  }

  @override
  String get commentAction => 'Comentar';

  @override
  String commentsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count comentários',
      one: '1 comentário',
      zero: 'nenhum comentário',
    );
    return '$_temp0';
  }

  @override
  String likesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count curtidas',
      one: '1 curtida',
      zero: 'nenhuma curtida',
    );
    return '$_temp0';
  }

  @override
  String get likePostAction => 'Curtir';

  @override
  String get unlikeAction => 'Descurtir';

  @override
  String get shareAction => 'Compartilhar';

  @override
  String get unsaveAction => 'Remover dos salvos';

  @override
  String get postSaved => 'Publicação salva';

  @override
  String get postUnsaved => 'Removida dos salvos';

  @override
  String get editPostAction => 'Editar publicação';

  @override
  String get deletePostAction => 'Excluir publicação';

  @override
  String get deletePostTitle => 'Excluir esta publicação?';

  @override
  String get deletePostBody =>
      'A publicação e as imagens são removidas para todos. Não dá para desfazer.';

  @override
  String get postDeleted => 'Publicação excluída';

  @override
  String get copyLinkAction => 'Copiar link';

  @override
  String get linkCopied => 'Link copiado';

  @override
  String get reportPostAction => 'Denunciar publicação';

  @override
  String get reportCommentAction => 'Denunciar comentário';

  @override
  String get reportMemberAction => 'Denunciar usuário';

  @override
  String blockMemberAction(String name) {
    return 'Bloquear $name';
  }

  @override
  String communityBlockBody(String name) {
    return 'Você não verá publicações nem comentários de $name, essa pessoa não poderá interagir com seu conteúdo e vocês não darão match. Não dá para desfazer.';
  }

  @override
  String get reportPostTitle => 'Denunciar publicação';

  @override
  String get reportCommentTitle => 'Denunciar comentário';

  @override
  String get contentReportIntro =>
      'Sua denúncia é confidencial e será analisada pela moderação.';

  @override
  String get contentReportDone =>
      'Denúncia enviada. Obrigado por ajudar a manter a comunidade segura.';

  @override
  String get reportReasonOffensive => 'Conteúdo ofensivo';

  @override
  String get reportReasonScam => 'Golpe';

  @override
  String get sendInChat => 'Enviar em uma conversa';

  @override
  String get shareNoChats =>
      'Você ainda não tem conversas abertas. Copie o link.';

  @override
  String sharePostTitle(String name) {
    return 'Enviar para $name?';
  }

  @override
  String get sharePostBody =>
      'Uma mensagem com o link desta publicação será enviada na conversa.';

  @override
  String sharedPostMessage(String link) {
    return 'Olha esta publicação no Skill Swap: $link';
  }

  @override
  String postSharedTo(String name) {
    return 'Enviado para $name';
  }

  @override
  String get openSharedPost => 'Ver publicação';

  @override
  String get postTitle => 'Publicação';

  @override
  String get commentsTitle => 'Comentários';

  @override
  String get commentsEmpty => 'Nenhum comentário ainda. Comece a conversa!';

  @override
  String get loadMoreComments => 'Carregar mais comentários';

  @override
  String get showReplies => 'Ver respostas';

  @override
  String get hideReplies => 'Ocultar respostas';

  @override
  String get replyAction => 'Responder';

  @override
  String replyingTo(String name) {
    return 'Respondendo a $name';
  }

  @override
  String get commentHint => 'Adicione um comentário…';

  @override
  String get commentMenuTooltip => 'Opções do comentário';

  @override
  String get commentTooFast => 'Aguarde um instante antes de comentar de novo.';

  @override
  String get deleteCommentAction => 'Excluir comentário';

  @override
  String get commentDeleted => 'Comentário excluído';

  @override
  String get postNotFoundTitle => 'Publicação indisponível';

  @override
  String get postNotFoundBody =>
      'Ela pode ter sido excluída, ou o link está errado.';

  @override
  String get backToCommunity => 'Voltar para a Comunidade';

  @override
  String get newPostTitle => 'Nova publicação';

  @override
  String get editPostTitle => 'Editar publicação';

  @override
  String get previewAction => 'Prévia';

  @override
  String get previewTitle => 'Prévia da publicação';

  @override
  String get addImagesAction => 'Adicionar imagens';

  @override
  String get removeImageAction => 'Remover imagem';

  @override
  String imagesHint(int max) {
    return 'Até $max imagens. Reduzimos o tamanho e removemos dados de localização.';
  }

  @override
  String get imagePickFailed => 'Não foi possível abrir suas fotos.';

  @override
  String imagesSkipped(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count imagens não puderam ser usadas',
      one: '1 imagem não pôde ser usada',
    );
    return '$_temp0';
  }

  @override
  String get editImagesLocked =>
      'As imagens não podem ser alteradas depois de publicar. Para trocar, exclua e publique de novo.';

  @override
  String get postDescriptionLabel => 'Descrição';

  @override
  String get postDescriptionHint => 'Conte sobre seu projeto, dica ou dúvida…';

  @override
  String get postTypeLabel => 'Tipo';

  @override
  String postSkillsLabel(int count, int max) {
    return 'Habilidades relacionadas ($count/$max)';
  }

  @override
  String get postSkillsHint =>
      'Do seu perfil. Habilidades que você ensina mostram o botão \"Quero aprender\".';

  @override
  String postSkillsMax(int max) {
    return 'Escolha até $max habilidades.';
  }

  @override
  String get postTagsLabel => 'Hashtags';

  @override
  String get postTagsHint => '#design #ui';

  @override
  String postTagsHelper(int count, int max) {
    return '$count/$max tags válidas (letras, números, _)';
  }

  @override
  String get visibilityLabel => 'Quem pode ver?';

  @override
  String get visibilityPublic => 'Público';

  @override
  String get visibilityPublicBody => 'Todos os membros do Skill Swap.';

  @override
  String get publishAction => 'Publicar';

  @override
  String get saveChangesAction => 'Salvar alterações';

  @override
  String preparingImages(int done, int total) {
    return 'Preparando imagens $done/$total…';
  }

  @override
  String get sendingPost => 'Enviando…';

  @override
  String get postEmptyError => 'Escreva algo ou adicione uma imagem.';

  @override
  String get postTooLongError => 'A descrição está longa demais.';

  @override
  String postTooFast(int seconds) {
    return 'Aguarde $seconds s para publicar de novo.';
  }

  @override
  String get postPublished => 'Publicação feita';

  @override
  String get postUpdated => 'Publicação atualizada';

  @override
  String get discardPostTitle => 'Descartar publicação?';

  @override
  String get discardPostBody => 'O que você escreveu será perdido.';

  @override
  String get keepEditingAction => 'Continuar editando';

  @override
  String get discardAction => 'Descartar';

  @override
  String get errorInvalidPost =>
      'Confira a publicação: ela está vazia ou longa demais.';

  @override
  String get memberMenuTooltip => 'Mais opções';

  @override
  String memberBlockedTitle(String name) {
    return 'Você bloqueou $name';
  }

  @override
  String get memberBlockedBody =>
      'O conteúdo dessa pessoa fica oculto para você.';

  @override
  String get memberNotFound => 'Membro não encontrado';

  @override
  String get portfolioTitle => 'Publicações e portfólio';

  @override
  String get portfolioEmpty => 'Nenhuma publicação ainda.';

  @override
  String get portfolioEmptyMine =>
      'Suas publicações aparecem aqui. Compartilhe seu primeiro projeto!';

  @override
  String get statPosts => 'Publicações';

  @override
  String get statFollowers => 'Seguidores';

  @override
  String get statFollowing => 'Seguindo';

  @override
  String get followAction => 'Seguir';

  @override
  String get followingAction => 'Seguindo';

  @override
  String get messageAction => 'Mensagem';

  @override
  String openPostSemantics(String text) {
    return 'Abrir publicação: $text';
  }

  @override
  String get followersEmpty => 'Nenhum seguidor ainda';

  @override
  String get followingEmpty => 'Ainda não segue ninguém';

  @override
  String get myPortfolioAction => 'Minhas publicações';

  @override
  String get savedTitle => 'Salvos';

  @override
  String get savedEmptyTitle => 'Nada salvo ainda';

  @override
  String get savedEmptyBody =>
      'Toque no marcador de uma publicação para guardá-la aqui. Só você vê esta lista.';

  @override
  String get searchHint => 'Pesquisar pessoas, publicações ou #tags';

  @override
  String get searchPeople => 'Pessoas';

  @override
  String get searchPosts => 'Publicações';

  @override
  String get searchSkills => 'Skills';

  @override
  String get searchPeopleHint => 'Digite pelo menos 2 letras de um nome.';

  @override
  String searchNoPeople(String term) {
    return 'Ninguém encontrado para \"$term\"';
  }

  @override
  String get searchPeopleLimit => 'A busca encontra o início do nome.';

  @override
  String get searchPostsHint => 'Pesquise uma palavra ou uma #tag.';

  @override
  String searchNoPosts(String term) {
    return 'Nenhuma publicação com \"$term\"';
  }

  @override
  String get searchPostsLimit => 'A busca usa uma palavra ou tag por vez.';

  @override
  String get searchSkillsHint =>
      'Escolha uma habilidade para ver quem ensina e publicações relacionadas.';

  @override
  String skillTeachersTitle(String skill) {
    return 'Quem ensina $skill';
  }

  @override
  String get skillTeachersEmpty => 'Ninguém ensina esta habilidade ainda.';

  @override
  String skillPostsTitle(String skill) {
    return 'Publicações sobre $skill';
  }

  @override
  String get skillPostsEmpty =>
      'Nenhuma publicação sobre esta habilidade ainda.';

  @override
  String get notificationsEmptyTitle => 'Nenhuma notificação';

  @override
  String get notificationsEmptyBody =>
      'Curtidas, comentários, seguidores e pedidos de aprendizado aparecem aqui.';

  @override
  String get markAllReadAction => 'Marcar como lidas';

  @override
  String get unreadLabel => 'não lida';

  @override
  String notificationLike(String name) {
    return '$name curtiu sua publicação';
  }

  @override
  String notificationComment(String name) {
    return '$name comentou na sua publicação';
  }

  @override
  String notificationReply(String name) {
    return '$name respondeu ao seu comentário';
  }

  @override
  String notificationFollow(String name) {
    return '$name começou a seguir você';
  }

  @override
  String notificationLearn(String name) {
    return '$name quer aprender com você';
  }

  @override
  String get contentReportSubmit => 'Enviar denúncia';

  @override
  String get deleteNotificationAction => 'Excluir notificação';

  @override
  String get postTypeKnowledge => 'Conhecimento';

  @override
  String get errorInvalidVideo =>
      'Use um vídeo MP4 de até 60 segundos e 2,3 MB.';

  @override
  String get addVideoAction => 'Adicionar vídeo';

  @override
  String get removeVideoAction => 'Remover vídeo';

  @override
  String get videoHint => 'Ou 1 vídeo de até 60 s (MP4, até 2,3 MB).';

  @override
  String get videoPickFailed => 'Não foi possível abrir seus vídeos.';

  @override
  String get preparingVideo => 'Preparando o vídeo…';

  @override
  String get playVideoAction => 'Reproduzir vídeo';

  @override
  String get pauseVideoAction => 'Pausar vídeo';

  @override
  String get replayVideoAction => 'Assistir de novo';

  @override
  String get fullscreenAction => 'Tela cheia';

  @override
  String get exitFullscreenAction => 'Sair da tela cheia';

  @override
  String get muteAction => 'Desativar som';

  @override
  String get unmuteAction => 'Ativar som';

  @override
  String get videoLoadFailed => 'Não foi possível carregar o vídeo.';

  @override
  String postVideoSemantics(String duration) {
    return 'Vídeo de $duration';
  }

  @override
  String get videoSelectedHint =>
      'Vídeo de até 60 s. Removemos dados de localização.';

  @override
  String get videoLoading => 'Carregando o vídeo…';

  @override
  String get videoLabel => 'Vídeo';

  @override
  String videoTooFast(int minutes) {
    return 'Você pode publicar outro vídeo em $minutes min.';
  }
}
