class OnboardingData {
  final String title;
  final String subtitle;
  final String? imageAsset; // sonra ekleyeceğiz

  const OnboardingData({
    required this.title,
    required this.subtitle,
    this.imageAsset,
  });
}

const onboardingPages = [
  OnboardingData(
    title: "Paranın Kontrolü Artık\nSenin Elinde",
    subtitle:
        "Harcağını her kuruş kolayca takip et.\nBütçeni belirle, anında kalanını gör.",
    imageAsset: 'assets/images/onboard1.png',
  ),
  OnboardingData(
    title: "Paranın Nereye\nGittiğini Bil",
    subtitle: "Market, yemek, ulaşım...\nTüm harcamaların tek ekranda.",
    imageAsset: 'assets/images/onboard2.png',
  ),
  OnboardingData(
    title: "Önceden Planla,\nRahat Et",
    subtitle: "Aylık bütçeni oluştur.\nKüçük adımlarla büyük fark yarat.",
    imageAsset: 'assets/images/onboard3.png',
  ),
];
