export default function Subdomain({
  params,
}: {
  params: { subdomain: string };
}) {
  return (
    <>
      <div>My sub-domain is {params.subdomain}</div>
    </>
  );
}
